class User < ApplicationRecord
  # Use Active Model's SecurePassword to handle password hashing
  has_secure_password

  # Encrypt GitHub token
  encrypts :github_token

  # Associations
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id'
  has_many :managed_projects, class_name: 'Project', foreign_key: 'manager_id'
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id'

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

  # Scopes for efficient querying
  scope :with_projects, -> { includes(:owned_projects, :managed_projects) }
  scope :admins, -> { where(role: 'admin') }
  scope :project_managers, -> { where(role: 'project_manager') }
  scope :developers, -> { where(role: 'developer') }
  scope :with_github_connected, -> { where.not(github_token: nil) }

  # Class methods for authentication with eager loading to prevent N+1 queries later
  def self.authenticate(email, password)
    # Eager load common associations that will likely be used after authentication
    user = includes(:owned_projects, :managed_projects).find_by(email: email)
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
  
  # Find user projects with eager loading to prevent N+1 queries
  def related_projects
    case role
    when 'admin'
      owned_projects.includes(:manager, :tasks)
    when 'project_manager'
      managed_projects.includes(:owner, :tasks)
    when 'developer'
      Project.joins(:tasks).where(tasks: { assignee_id: id })
             .distinct.includes(:owner, :manager, :tasks)
    else
      Project.none
    end
  end
  
  # Check if user has connected GitHub account
  def github_connected?
    github_token.present?
  end
end
