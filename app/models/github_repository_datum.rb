class GithubRepositoryDatum < ApplicationRecord
  belongs_to :project
  
  validates :full_name, presence: true
  validates :name, presence: true
  validates :url, presence: true
  validates :last_synced_at, presence: true
  
  # Ensure uniqueness of the repository for each project
  validates :full_name, uniqueness: { scope: :project_id }
  
  # Scope for finding repositories that need updating (older than 24 hours)
  scope :needs_update, -> { where('last_synced_at < ?', 24.hours.ago) }
  
  # Class method to find or initialize by project and repo name
  def self.find_or_initialize_by_project_and_repo(project, repo_name)
    find_or_initialize_by(project_id: project.id, full_name: repo_name)
  end
  
  # Update the repository data from a GitHub API response
  def update_from_github_data(repository)
    self.name = repository.name
    self.full_name = repository.full_name
    self.description = repository.description
    self.url = repository.html_url
    self.stargazers_count = repository.stargazers_count
    self.forks_count = repository.forks_count
    self.open_issues_count = repository.open_issues_count
    self.last_synced_at = Time.current
    save!
  end
end 