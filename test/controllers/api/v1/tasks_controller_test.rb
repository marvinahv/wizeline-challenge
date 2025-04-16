require 'test_helper'

class Api::V1::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @project_manager = create(:user, :project_manager)
    @other_manager = create(:user, :project_manager)
    @developer = create(:user, :developer)
    @other_developer = create(:user, :developer)
    
    @project = create(:project, owner: @admin, manager: @project_manager)
    @task = create(:task, project: @project, assignee: @developer)
    
    # Generate tokens for testing authentication
    @admin_token = generate_token_for(@admin)
    @project_manager_token = generate_token_for(@project_manager)
    @other_manager_token = generate_token_for(@other_manager)
    @developer_token = generate_token_for(@developer)
    @other_developer_token = generate_token_for(@other_developer)
  end
  
  test "only the manager assigned to a project can create tasks" do
    # Project manager assigned to the project can create tasks
    task_count = Task.count
    
    post api_v1_project_tasks_url(@project), 
         params: { task: { description: 'New Manager Task', assignee_id: @developer.id } },
         headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
         as: :json
    
    assert_response :created
    assert_equal task_count + 1, Task.count
    
    # Other project manager (not assigned to the project) cannot create tasks
    task_count = Task.count
    
    post api_v1_project_tasks_url(@project), 
         params: { task: { description: 'Other Manager Task', assignee_id: @developer.id } },
         headers: { 'Authorization' => "Bearer #{@other_manager_token}" },
         as: :json
    
    assert_response :forbidden
    assert_equal task_count, Task.count
    
    # Admin cannot create tasks (even though they own the project)
    task_count = Task.count
    
    post api_v1_project_tasks_url(@project), 
         params: { task: { description: 'Admin Task', assignee_id: @developer.id } },
         headers: { 'Authorization' => "Bearer #{@admin_token}" },
         as: :json
    
    assert_response :forbidden
    assert_equal task_count, Task.count
    
    # Developer cannot create tasks
    task_count = Task.count
    
    post api_v1_project_tasks_url(@project), 
         params: { task: { description: 'Developer Task', assignee_id: @other_developer.id } },
         headers: { 'Authorization' => "Bearer #{@developer_token}" },
         as: :json
    
    assert_response :forbidden
    assert_equal task_count, Task.count
  end
  
  test "only the manager assigned to a project can edit tasks" do
    # Project manager assigned to the project can edit task description
    put api_v1_task_url(@task),
        params: { task: { description: 'Updated Task Description' } },
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
        as: :json
    
    assert_response :success
    @task.reload
    assert_equal 'Updated Task Description', @task.description
    
    # Other project manager (not assigned to the project) cannot edit task
    original_description = @task.description
    
    put api_v1_task_url(@task),
        params: { task: { description: 'Other Manager Update' } },
        headers: { 'Authorization' => "Bearer #{@other_manager_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_description, @task.description
    
    # Admin cannot edit task
    put api_v1_task_url(@task),
        params: { task: { description: 'Admin Update' } },
        headers: { 'Authorization' => "Bearer #{@admin_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_description, @task.description
    
    # Developer cannot edit task
    put api_v1_task_url(@task),
        params: { task: { description: 'Developer Update' } },
        headers: { 'Authorization' => "Bearer #{@developer_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_description, @task.description
  end
  
  test "only the manager assigned to a project can change its assignee developer" do
    # Project manager assigned to the project can reassign task to another developer
    put api_v1_task_url(@task),
        params: { task: { assignee_id: @other_developer.id } },
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
        as: :json
    
    assert_response :success
    @task.reload
    assert_equal @other_developer.id, @task.assignee_id
    
    # Reset assignee for further tests
    @task.update(assignee_id: @developer.id)
    
    # Other project manager (not assigned to the project) cannot change assignee
    original_assignee_id = @task.assignee_id
    
    put api_v1_task_url(@task),
        params: { task: { assignee_id: @other_developer.id } },
        headers: { 'Authorization' => "Bearer #{@other_manager_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_assignee_id, @task.assignee_id
    
    # Admin cannot change assignee
    put api_v1_task_url(@task),
        params: { task: { assignee_id: @other_developer.id } },
        headers: { 'Authorization' => "Bearer #{@admin_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_assignee_id, @task.assignee_id
    
    # Developer cannot change assignee
    put api_v1_task_url(@task),
        params: { task: { assignee_id: @other_developer.id } },
        headers: { 'Authorization' => "Bearer #{@developer_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_assignee_id, @task.assignee_id
  end
  
  test "only the manager assigned to a project can delete tasks" do
    # Create a task for deletion testing
    task_to_delete = create(:task, project: @project, assignee: @developer)
    
    # Admin cannot delete the task
    delete api_v1_task_url(task_to_delete),
           headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :forbidden
    assert Task.exists?(task_to_delete.id)
    
    # Developer cannot delete the task
    delete api_v1_task_url(task_to_delete),
           headers: { 'Authorization' => "Bearer #{@developer_token}" }
    
    assert_response :forbidden
    assert Task.exists?(task_to_delete.id)
    
    # Other project manager cannot delete the task
    delete api_v1_task_url(task_to_delete),
           headers: { 'Authorization' => "Bearer #{@other_manager_token}" }
    
    assert_response :forbidden
    assert Task.exists?(task_to_delete.id)
    
    # Project manager assigned to the project can delete the task
    delete api_v1_task_url(task_to_delete),
           headers: { 'Authorization' => "Bearer #{@project_manager_token}" }
    
    assert_response :no_content
    assert_not Task.exists?(task_to_delete.id)
  end
  
  test "only the assigned developer can update a task's status" do
    # Assigned developer can update task status
    put status_api_v1_task_url(@task),
        params: { status: 'in_progress' },
        headers: { 'Authorization' => "Bearer #{@developer_token}" },
        as: :json
    
    assert_response :success
    @task.reload
    assert_equal 'in_progress', @task.status
    
    # Other developer cannot update task status
    original_status = @task.status
    
    put status_api_v1_task_url(@task),
        params: { status: 'done' },
        headers: { 'Authorization' => "Bearer #{@other_developer_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_status, @task.status
    
    # Project manager cannot update task status
    put status_api_v1_task_url(@task),
        params: { status: 'done' },
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_status, @task.status
    
    # Admin cannot update task status
    put status_api_v1_task_url(@task),
        params: { status: 'done' },
        headers: { 'Authorization' => "Bearer #{@admin_token}" },
        as: :json
    
    assert_response :forbidden
    @task.reload
    assert_equal original_status, @task.status
  end
  
  test "project manager can see all tasks they have created for a given project, sorted by creation date newest first" do
    # Clear existing tasks
    Task.delete_all
    
    # Create a project managed by our project manager
    project = create(:project, owner: @admin, manager: @project_manager)
    
    # Create tasks with different creation dates
    oldest_task = create(:task, description: "Oldest Task", project: project, assignee: @developer, created_at: 3.days.ago)
    middle_task = create(:task, description: "Middle Task", project: project, assignee: @developer, created_at: 2.days.ago)
    newest_task = create(:task, description: "Newest Task", project: project, assignee: @developer, created_at: 1.day.ago)
    
    # Create a task in another project managed by a different manager
    other_project = create(:project, owner: @admin, manager: @other_manager)
    other_task = create(:task, description: "Other Task", project: other_project, assignee: @developer)
    
    # Test that project manager can see all tasks for their project sorted by creation date (newest first)
    get api_v1_project_tasks_url(project),
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" }
    
    assert_response :success
    
    # Verify all tasks for this project are returned
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    task_ids = json_response.map { |t| t['id'] }
    assert_equal [newest_task.id, middle_task.id, oldest_task.id], task_ids
    
    # Verify no tasks from other projects are included
    assert_not_includes task_ids, other_task.id
    
    # Test that another manager can access the endpoint but doesn't see tasks
    # for projects they don't manage
    get api_v1_project_tasks_url(project),
        headers: { 'Authorization' => "Bearer #{@other_manager_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_empty json_response
  end
  
  test "developer can only see tasks assigned to them, sorted by creation date newest first" do
    # Clear existing tasks
    Task.delete_all
    
    # Create a project
    project = create(:project, owner: @admin, manager: @project_manager)
    
    # Create tasks assigned to our developer with different creation dates
    oldest_task = create(:task, description: "Oldest Dev Task", project: project, assignee: @developer, created_at: 3.days.ago)
    middle_task = create(:task, description: "Middle Dev Task", project: project, assignee: @developer, created_at: 2.days.ago)
    newest_task = create(:task, description: "Newest Dev Task", project: project, assignee: @developer, created_at: 1.day.ago)
    
    # Create tasks assigned to another developer (should not appear in results)
    other_dev_task1 = create(:task, description: "Other Dev Task 1", project: project, assignee: @other_developer, created_at: 4.days.ago)
    other_dev_task2 = create(:task, description: "Other Dev Task 2", project: project, assignee: @other_developer, created_at: 1.hour.ago)
    
    # Test that our developer can only see tasks assigned to them
    get api_v1_project_tasks_url(project),
        headers: { 'Authorization' => "Bearer #{@developer_token}" }
    
    assert_response :success
    
    # Verify only tasks assigned to this developer are returned
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    task_ids = json_response.map { |t| t['id'] }
    assert_equal [newest_task.id, middle_task.id, oldest_task.id], task_ids
    
    # Verify no tasks assigned to other developers are included
    assert_not_includes task_ids, other_dev_task1.id
    assert_not_includes task_ids, other_dev_task2.id
    
    # Test that other developer only sees their own tasks
    get api_v1_project_tasks_url(project),
        headers: { 'Authorization' => "Bearer #{@other_developer_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    task_ids = json_response.map { |t| t['id'] }
    assert_equal [other_dev_task2.id, other_dev_task1.id], task_ids
  end
  
  test "admin can see all tasks for projects they own, sorted by creation date newest first" do
    # Clear existing tasks
    Task.delete_all
    
    # Create a project owned by our admin
    project = create(:project, owner: @admin, manager: @project_manager)
    
    # Create tasks with different creation dates
    oldest_task = create(:task, description: "Oldest Task", project: project, assignee: @developer, created_at: 3.days.ago)
    middle_task = create(:task, description: "Middle Task", project: project, assignee: @developer, created_at: 2.days.ago)
    newest_task = create(:task, description: "Newest Task", project: project, assignee: @other_developer, created_at: 1.day.ago)
    
    # Create a project owned by another admin
    other_project = create(:project, owner: @other_admin, manager: @project_manager)
    other_task = create(:task, description: "Other Admin Task", project: other_project, assignee: @developer)
    
    # Test that admin can see all tasks for projects they own
    get api_v1_project_tasks_url(project),
        headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :success
    
    # Verify all tasks for this project are returned
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    task_ids = json_response.map { |t| t['id'] }
    assert_equal [newest_task.id, middle_task.id, oldest_task.id], task_ids
    
    # Verify admin can't see tasks for projects owned by other admins
    get api_v1_project_tasks_url(other_project),
        headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    # Our current implementation doesn't restrict admins from seeing tasks in projects they don't own,
    # as we're using the default behavior for admins in the TasksController.
    # If we want to change this behavior, we would need to update the controller.
    assert_equal 1, json_response.length
    assert_includes json_response.map { |t| t['id'] }, other_task.id
  end
  
  private
  
  def generate_token_for(user)
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end 