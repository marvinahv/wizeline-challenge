require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = build(:project, owner: admin, manager: project_manager)
    assert project.valid?
  end

  test "requires owner to be admin" do
    # Try with developer user
    developer = create(:user, :developer)
    project_manager = create(:user, :project_manager)
    project = build(:project, owner: developer, manager: project_manager)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Owner must be an admin user"

    # Try with project manager user
    manager = create(:user, :project_manager) 
    project = build(:project, owner: manager, manager: project_manager)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Owner must be an admin user"

    # Try with admin user - should succeed
    admin = create(:user, :admin)
    project = build(:project, owner: admin, manager: project_manager)
    assert project.valid?
  end

  test "requires name" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = build(:project, name: nil, owner: admin, manager: project_manager)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Name can't be blank"
  end

  test "name must be unique" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    existing_project = create(:project, name: "Unique Project", owner: admin, manager: project_manager)
    project = build(:project, name: "Unique Project", owner: admin, manager: project_manager)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Name has already been taken"
  end

  test "requires a project manager" do
    admin = create(:user, :admin)
    project = build(:project, owner: admin, manager: nil)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Manager must exist"
  end

  test "requires manager to be a project manager role" do
    admin_owner = create(:user, :admin)

    # Try with developer user as manager
    developer = create(:user, :developer)
    project = build(:project, owner: admin_owner, manager: developer)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Manager must have project_manager role"

    # Try with admin user as manager
    admin_manager = create(:user, :admin)
    project = build(:project, owner: admin_owner, manager: admin_manager) 
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Manager must have project_manager role"

    # Try with project manager - should succeed
    project_manager = create(:user, :project_manager)
    project = build(:project, owner: admin_owner, manager: project_manager)
    assert project.valid?
  end

  test "belongs to an admin owner" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = create(:project, owner: admin, manager: project_manager)
    assert_equal admin, project.owner
    assert_equal "admin", project.owner.role
  end

  test "belongs to a project manager" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = create(:project, owner: admin, manager: project_manager)
    assert_equal project_manager, project.manager
    assert_equal "project_manager", project.manager.role
  end
  
  test "can have a github repository associated" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    repo_name = "octocat/Hello-World"
    project = create(:project, owner: admin, manager: project_manager, github_repo: repo_name)
    assert_equal repo_name, project.github_repo
  end
  
  test "github_repo format is valid" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    
    # Valid format: owner/repo
    valid_repo = build(:project, owner: admin, manager: project_manager, github_repo: "octocat/Hello-World")
    assert valid_repo.valid?
    
    # Invalid formats
    invalid_formats = [
      "octocat", # Missing repository name
      "octocat/", # Missing repository name
      "/Hello-World", # Missing owner
      "octocat/Hello/World", # Too many segments
      "octo@cat/Hello-World" # Invalid character in owner
    ]
    
    invalid_formats.each do |invalid_repo|
      project = build(:project, owner: admin, manager: project_manager, github_repo: invalid_repo)
      assert_not project.valid?, "#{invalid_repo} should be invalid"
      assert_includes project.errors.full_messages, "Github repo format is invalid"
    end
  end
  
  test "github_repo can be nil" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = build(:project, owner: admin, manager: project_manager, github_repo: nil)
    assert project.valid?
  end
  
  test "github_repo can be blank" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = build(:project, owner: admin, manager: project_manager, github_repo: "")
    assert project.valid?
  end
end 