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
  
  # Tasks count method using cache when available
  def tasks_count
    read_attribute(:tasks_count) || tasks.count
  end
  
  # Task status counts using a single query
  def task_status_counts
    tasks.group(:status).count
  end
  
  # Methods to efficiently count tasks by status
  def todo_tasks_count
    task_status_counts['todo'] || 0
  end
  
  def in_progress_tasks_count
    task_status_counts['in_progress'] || 0
  end
  
  def done_tasks_count
    task_status_counts['done'] || 0
  end

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
