require 'test_helper'

class GithubServiceTest < ActiveSupport::TestCase
  setup do
    # Ensure the GitHub token environment variable is set
    unless ENV["TEST_USER_GITHUB_TOKEN"]
      skip "TEST_USER_GITHUB_TOKEN environment variable not set. Skipping GitHub API tests."
    end
    
    # Create a test user with GitHub token
    @user = create(:user, :with_github)
    @service = GithubService.new(@user.github_token)
    @test_repo = "octocat/Hello-World" # Use a public GitHub repo for consistent results
  end
  
  test "fetch_repository returns repository data" do
    VCR.use_cassette("github/repository") do
      repository = @service.fetch_repository(@test_repo)
      
      # Test that we got valid data back
      assert_equal @test_repo, repository.full_name
      assert repository.description.present?
      assert repository.stargazers_count.is_a?(Integer)
      assert repository.forks_count.is_a?(Integer)
      assert repository.open_issues_count.is_a?(Integer)
      assert repository.created_at.is_a?(Time)
      assert repository.updated_at.is_a?(Time)
    end
  end
  
  test "fetch_repository handles API errors gracefully" do
    VCR.use_cassette("github/repository_not_found", allow_playback_repeats: true) do
      # Force an error by requesting a non-existent repository
      repository = @service.fetch_repository("this-repo/does-not-exist")
      
      # Should return nil when an error occurs
      assert_nil repository
    end
  end
  
  test "fetch_commit_activity returns commit data" do
    VCR.use_cassette("github/commit_activity", record: :new_episodes) do
      commit_activity = @service.fetch_commit_activity(@test_repo)
      
      # Test that we always get an array back for valid repos
      assert commit_activity.is_a?(Array)
      
      # If there's data, check its structure
      unless commit_activity.empty?
        sample = commit_activity.first
        assert sample.respond_to?(:week), "Activity sample should respond to :week"
        assert sample.respond_to?(:total), "Activity sample should respond to :total" 
        assert sample.respond_to?(:days), "Activity sample should respond to :days"
        
        if sample.respond_to?(:days)
          assert sample.days.is_a?(Array), "Days should be an array"
        end
      end
    end
  end
  
  test "fetch_commit_activity handles API errors gracefully" do
    VCR.use_cassette("github/commit_activity_not_found", allow_playback_repeats: true) do
      # Force an error by requesting a non-existent repository
      commit_activity = @service.fetch_commit_activity("this-repo/does-not-exist")
      
      # Should return nil when an error occurs
      assert_nil commit_activity
    end
  end
end 