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
end 