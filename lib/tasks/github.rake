namespace :github do
  desc "Sync all GitHub repositories for projects"
  task sync_all: :environment do
    puts "Starting synchronization of all GitHub repositories..."
    count = Project.where.not(github_repo: [nil, ""]).count
    puts "Found #{count} projects with GitHub repositories."
    
    SyncGithubRepositoryJob.schedule_all
    puts "All sync jobs have been scheduled."
  end
  
  desc "Sync GitHub repositories that need updating (older than 24 hours)"
  task sync_outdated: :environment do
    puts "Starting synchronization of outdated GitHub repositories..."
    
    # Get projects whose GitHub data is older than 24 hours or doesn't exist yet
    projects_to_update = Project.left_joins(:github_repository_datum)
                               .where.not(github_repo: [nil, ""])
                               .where("github_repository_data.id IS NULL OR github_repository_data.last_synced_at < ?", 24.hours.ago)
    
    count = projects_to_update.count
    puts "Found #{count} projects with outdated GitHub repository data."
    
    SyncGithubRepositoryJob.schedule_updates
    puts "All sync jobs for outdated repositories have been scheduled."
  end
  
  desc "Cleanup orphaned GitHub repository data (where project no longer exists or has no GitHub repo)"
  task cleanup: :environment do
    puts "Starting cleanup of orphaned GitHub repository data..."
    
    # Find orphaned repository data
    orphaned = GithubRepositoryDatum.left_joins(:project)
                                   .where("projects.id IS NULL OR projects.github_repo = '' OR projects.github_repo IS NULL")
    
    count = orphaned.count
    puts "Found #{count} orphaned GitHub repository data records."
    
    if count > 0
      orphaned.destroy_all
      puts "Deleted #{count} orphaned records."
    end
  end
end 