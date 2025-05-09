require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @project_manager = create(:user, :project_manager)
    @developer = create(:user, :developer)
    @project = create(:project, owner: @admin, manager: @project_manager)
  end

  test "valid task" do
    task = build(:task, project: @project, assignee: @developer)
    assert task.valid?
  end

  test "belongs to a project" do
    task = create(:task, project: @project, assignee: @developer)
    assert_equal @project, task.project
  end

  test "requires a project" do
    task = build(:task, project: nil, assignee: @developer)
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Project must exist"
  end

  test "requires a description" do
    task = build(:task, description: nil, project: @project, assignee: @developer)
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Description can't be blank"
  end

  test "requires an assigned developer" do
    task = build(:task, project: @project, assignee: nil)
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Assignee must exist"
  end

  test "assignee must be a developer" do
    # Try with admin
    task = build(:task, project: @project, assignee: @admin)
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Assignee must be a developer"

    # Try with project manager
    task = build(:task, project: @project, assignee: @project_manager)
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Assignee must be a developer"

    # Try with developer - should succeed
    task = build(:task, project: @project, assignee: @developer)
    assert task.valid?
  end
  
  test "default status is todo" do
    task = Task.new(project: @project, description: "Test task", assignee: @developer)
    assert_equal "todo", task.status
  end
  
  test "status must be valid" do
    task = build(:task, project: @project, assignee: @developer)
    
    # Valid status values
    task.status = "todo"
    assert task.valid?
    
    task.status = "in_progress"
    assert task.valid?
    
    task.status = "done"
    assert task.valid?
    
    # Invalid status value
    task.status = "invalid_status"
    assert_not task.valid?
    assert_includes task.errors.full_messages, "Status is not included in the list"
  end
end 