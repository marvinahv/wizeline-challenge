class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  belongs_to :manager, class_name: 'User'
  has_many :tasks, dependent: :destroy
  has_one :github_repository_datum, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :github_repo, format: { 
    with: /\A[a-zA-Z0-9\-_]+\/[a-zA-Z0-9\-_]+\z/, 
    message: 'format is invalid',
    allow_blank: true
  }
  validate :owner_must_be_admin
  validate :manager_must_be_project_manager

  private

  def owner_must_be_admin
    unless owner&.role == 'admin'
      errors.add(:owner, 'must be an admin user')
    end
  end

  def manager_must_be_project_manager
    unless manager&.role == 'project_manager'
      errors.add(:manager, 'must have project_manager role')
    end
  end
end
