class Task < ApplicationRecord
  # Status constants
  STATUSES = %w[todo in_progress done].freeze
  
  # Associations
  belongs_to :project, counter_cache: true
  belongs_to :assignee, class_name: 'User'
  
  # Validations
  validates :description, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :assignee_must_be_developer
  
  # Default values
  after_initialize :set_default_status, if: :new_record?
  
  # Scopes for efficient querying
  scope :todo, -> { where(status: 'todo') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :done, -> { where(status: 'done') }
  
  private
  
  def assignee_must_be_developer
    unless assignee&.role == 'developer'
      errors.add(:assignee, 'must be a developer')
    end
  end
  
  def set_default_status
    self.status ||= 'todo'
  end
end 