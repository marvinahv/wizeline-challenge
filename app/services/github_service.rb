# app/services/github_service.rb
class GithubService
  attr_reader :client

  def initialize(token)
    # Never log or expose the token
    @client = Octokit::Client.new(access_token: token)
  end

  # Fetches basic repository data
  def fetch_repository(repo_name)
    Rails.logger.info "Fetching repository data for: #{repo_name}"
    
    begin
      repository = client.repository(repo_name)
      
      # Log repository details but don't print to console in normal operation
      Rails.logger.debug "Repository: #{repository.full_name}"
      Rails.logger.debug "Description: #{repository.description}"
      Rails.logger.debug "Stars: #{repository.stargazers_count}"
      Rails.logger.debug "Forks: #{repository.forks_count}"
      Rails.logger.debug "Open Issues: #{repository.open_issues_count}"
      
      # Log rate limit info without exposing sensitive data
      rate_limit = client.rate_limit
      Rails.logger.info "GitHub API Rate Limit: #{rate_limit.remaining}/#{rate_limit.limit}"
      Rails.logger.info "Resets at: #{rate_limit.resets_at}"
      
      return repository
    rescue Octokit::Error => e
      # Log errors without potentially exposing the token in the error message
      Rails.logger.error "GitHub API Error for #{repo_name}: #{e.class} - #{e.message.gsub(/token \w+/, 'token [FILTERED]')}"
      return nil
    end
  end
  
  # Fetches commit activity for the last year
  def fetch_commit_activity(repo_name)
    Rails.logger.info "Fetching commit activity for: #{repo_name}"
    
    begin
      # This returns an array of weekly commit counts for the last year
      # Note: GitHub might return nil if stats aren't computed yet
      # or return empty array for repos with no activity
      commit_activity = client.commit_activity_stats(repo_name)
      
      # Log rate limit info without exposing sensitive data
      rate_limit = client.rate_limit
      Rails.logger.info "GitHub API Rate Limit: #{rate_limit.remaining}/#{rate_limit.limit}"
      Rails.logger.info "Resets at: #{rate_limit.resets_at}"
      
      # If GitHub returns nil (stats not yet computed), return empty array
      # for consistency and easier handling in controllers
      return commit_activity.nil? ? [] : commit_activity
    rescue Octokit::Error => e
      # Log errors without potentially exposing the token in the error message
      Rails.logger.error "GitHub API Error for #{repo_name}: #{e.class} - #{e.message.gsub(/token \w+/, 'token [FILTERED]')}"
      return nil
    rescue StandardError => e
      # Catch any other unexpected errors
      Rails.logger.error "Unexpected error fetching commit activity for #{repo_name}: #{e.class} - #{e.message}"
      return nil
    end
  end
end 