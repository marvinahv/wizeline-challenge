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
  
  test "only owner admin can update project name using CanCanCan" do
    admin = create(:user, :admin)
    other_admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = create(:project, name: "Original Name", owner: admin, manager: project_manager)
    
    # Owner admin can update name
    ability = Ability.new(admin)
    assert ability.can?(:update_name, project)
    
    # Other admin cannot update name
    ability = Ability.new(other_admin)
    assert ability.cannot?(:update_name, project)
    
    # Project manager cannot update name
    ability = Ability.new(project_manager)
    assert ability.cannot?(:update_name, project)
    
    # Developer cannot update name
    developer = create(:user, :developer)
    ability = Ability.new(developer)
    assert ability.cannot?(:update_name, project)
  end
  
  test "only owner admin can update project manager using CanCanCan" do
    admin = create(:user, :admin)
    other_admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    project = create(:project, owner: admin, manager: project_manager)
    new_manager = create(:user, :project_manager)
    
    # Owner admin can update manager
    ability = Ability.new(admin)
    assert ability.can?(:update_manager, project)
    
    # Other admin cannot update manager
    ability = Ability.new(other_admin)
    assert ability.cannot?(:update_manager, project)
    
    # Project manager cannot update manager
    ability = Ability.new(project_manager)
    assert ability.cannot?(:update_manager, project)
    
    # Developer cannot update manager
    developer = create(:user, :developer)
    ability = Ability.new(developer)
    assert ability.cannot?(:update_manager, project)
  end
end 