require 'test_helper'

class SyncGithubRepositoryJobTest < ActiveJob::TestCase
  setup do
    # Create test user with GitHub token
    @admin = create(:user, :admin, :with_github)
    
    # Create a test project with GitHub repo
    @project = create(:project, owner: @admin, manager: create(:user, :project_manager), github_repo: "octocat/Hello-World")
  end
  
  test "job enqueues with project ID" do
    assert_enqueued_with(job: SyncGithubRepositoryJob, args: [@project.id]) do
      SyncGithubRepositoryJob.perform_later(@project.id)
    end
  end
  
  test "job syncs GitHub data for a project" do
    # Skip if no GitHub token is provided
    unless ENV["TEST_USER_GITHUB_TOKEN"]
      skip "TEST_USER_GITHUB_TOKEN environment variable not set. Skipping GitHub API test."
    end
    
    VCR.use_cassette("github/sync_repository_job", record: :new_episodes) do
      # Ensure no repository data exists yet
      assert_nil @project.github_repository_datum
      
      # Perform the job
      perform_enqueued_jobs do
        SyncGithubRepositoryJob.perform_later(@project.id)
      end
      
      # Reload the project to get the latest associations
      @project.reload
      
      # Assert that repository data was created
      assert_not_nil @project.github_repository_datum
      
      # Verify data was properly stored
      repo_data = @project.github_repository_datum
      assert_equal "Hello-World", repo_data.name
      assert_equal "octocat/Hello-World", repo_data.full_name
      assert_not_nil repo_data.url
      assert repo_data.last_synced_at > 5.minutes.ago
    end
  end
  
  test "job handles missing GitHub token gracefully" do
    # Create admin without GitHub token
    admin_without_token = create(:user, :admin)
    project_without_token = create(:project, owner: admin_without_token, manager: create(:user, :project_manager), github_repo: "octocat/Hello-World")
    
    # Should not raise an error
    assert_nothing_raised do
      perform_enqueued_jobs do
        SyncGithubRepositoryJob.perform_later(project_without_token.id)
      end
    end
    
    # No data should be created
    project_without_token.reload
    assert_nil project_without_token.github_repository_datum
  end
  
  test "job handles non-existent project gracefully" do
    non_existent_id = 9999
    
    # Should not raise an error
    assert_nothing_raised do
      perform_enqueued_jobs do
        SyncGithubRepositoryJob.perform_later(non_existent_id)
      end
    end
  end
  
  test "job schedules updates for all outdated repositories" do
    # Create another project with GitHub repo
    other_project = create(:project, owner: @admin, manager: create(:user, :project_manager), github_repo: "rails/rails")
    
    # Create repository data that is older than 24 hours for the first project
    old_time = 25.hours.ago
    create(:github_repository_datum, project: @project, last_synced_at: old_time)
    
    # Schedule updates - expecting 2 jobs because:
    # 1. @project has outdated GitHub data
    # 2. other_project doesn't have any GitHub data yet
    assert_enqueued_jobs 2 do
      SyncGithubRepositoryJob.schedule_updates
    end
  end
end 