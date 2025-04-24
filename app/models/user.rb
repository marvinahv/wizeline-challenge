class User < ApplicationRecord
  # Use Active Model's SecurePassword to handle password hashing
  has_secure_password

  # Encrypt GitHub token
  encrypts :github_token

  # Custom password validation
  PASSWORD_REQUIREMENTS = /\A
    (?=.*\d)           # Must contain at least one number
    (?=.*[a-z])        # Must contain at least one lowercase letter
    (?=.*[A-Z])        # Must contain at least one uppercase letter
    (?=.*[[:^alnum:]]) # Must contain at least one symbol
  /x

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, 
                     length: { minimum: 8 }, 
                     format: { with: PASSWORD_REQUIREMENTS,
                               message: 'must include at least one uppercase letter, one lowercase letter, one number, and one special character' },
                     allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[admin project_manager developer] }

  # Class methods for authentication
  def self.authenticate(email, password)
    user = find_by(email: email)
    return nil unless user
    user.authenticate(password) ? user : nil
  end

  # Generate JWT token for this user
  def generate_jwt
    expiration = 24.hours.from_now.to_i
    
    payload = {
      user_id: id,
      role: role,
      exp: expiration
    }
    
    JWT.encode(
      payload,
      Rails.application.credentials.secret_key_base,
      'HS256'
    )
  end
  
  # Check if user has connected GitHub account
  def github_connected?
    github_token.present?
  end
end
