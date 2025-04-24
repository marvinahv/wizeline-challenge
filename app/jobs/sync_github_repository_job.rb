class SyncGithubRepositoryJob < ApplicationJob
  queue_as :default
  
  # Retry job up to 3 times with exponential backoff in case of API rate limiting or network issues
  retry_on Octokit::TooManyRequests, wait: :exponentially_longer, attempts: 3
  retry_on Octokit::InternalServerError, wait: 30.seconds, attempts: 3
  retry_on Octokit::BadGateway, wait: 30.seconds, attempts: 3
  
  # Discard job if GitHub returns 404 (repository doesn't exist)
  discard_on Octokit::NotFound
  
  def perform(project_id)
    # Eager load owner to prevent N+1 query when checking github_connected?
    project = Project.includes(:owner, :github_repository_datum).find_by(id: project_id)
    return unless project && project.github_repo.present?
    
    # Find owner of the project for GitHub token
    admin = project.owner
    return unless admin&.github_connected?
    
    # Initialize GitHub service with admin's token
    github_service = GithubService.new(admin.github_token)
    
    # Fetch repository data from GitHub
    repository = github_service.fetch_repository(project.github_repo)
    return unless repository
    
    # Find or initialize the repository data record
    repo_data = GithubRepositoryDatum.find_or_initialize_by_project_and_repo(project, project.github_repo)
    
    # Update repo data with the fetched information
    repo_data.update_from_github_data(repository)
    
    # Log successful update
    Rails.logger.info "Successfully synced GitHub repository data for project #{project.id}: #{project.github_repo}"
  rescue StandardError => e
    # Log errors but don't raise them (to avoid job retries for unexpected errors)
    Rails.logger.error "Error syncing GitHub repository for project #{project_id}: #{e.class} - #{e.message}"
  end
  
  # Class method to schedule sync jobs for all projects with GitHub repositories
  def self.schedule_all
    # Preload all projects with GitHub repos in a single query
    projects_with_github = Project.includes(:owner).where.not(github_repo: [nil, ""])
    projects_with_github.find_each do |project|
      SyncGithubRepositoryJob.perform_later(project.id)
    end
  end
  
  # Class method to schedule sync jobs for projects needing updates
  def self.schedule_updates
    # Get projects whose GitHub data is older than 24 hours or doesn't exist yet
    # Use a single query with joins to get all needed data
    projects_to_update = Project.includes(:owner)
                               .left_joins(:github_repository_datum)
                               .where.not(github_repo: [nil, ""])
                               .where("github_repository_data.id IS NULL OR github_repository_data.last_synced_at < ?", 24.hours.ago)
    
    projects_to_update.find_each do |project|
      SyncGithubRepositoryJob.perform_later(project.id)
    end
  end
end 