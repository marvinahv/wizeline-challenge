require 'test_helper'

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @other_admin = create(:user, :admin)
    @project_manager = create(:user, :project_manager)
    @developer = create(:user, :developer)
    
    @project = create(:project, owner: @admin, manager: @project_manager)
    
    # Generate tokens for testing authentication
    @admin_token = generate_token_for(@admin)
    @other_admin_token = generate_token_for(@other_admin)
    @project_manager_token = generate_token_for(@project_manager)
    @developer_token = generate_token_for(@developer)
  end

  test "only admins can create new projects" do
    # Admin can create projects
    project_count = Project.count
    
    post api_v1_projects_url, 
         params: { project: { name: 'New Project', manager_id: @project_manager.id } },
         headers: { 'Authorization' => "Bearer #{@admin_token}" },
         as: :json
    
    assert_response :created
    assert_equal project_count + 1, Project.count
    
    # Project manager cannot create projects
    project_count = Project.count
    
    post api_v1_projects_url, 
         params: { project: { name: 'Manager Project', manager_id: @project_manager.id } },
         headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
         as: :json
    
    assert_response :forbidden
    assert_equal project_count, Project.count
    
    # Developer cannot create projects
    project_count = Project.count
    
    post api_v1_projects_url, 
         params: { project: { name: 'Developer Project', manager_id: @project_manager.id } },
         headers: { 'Authorization' => "Bearer #{@developer_token}" },
         as: :json
    
    assert_response :forbidden
    assert_equal project_count, Project.count
  end
  
  test "only the admin that created a project can update its name" do
    # Admin owner can update project name
    put api_v1_project_url(@project),
        params: { project: { name: 'Updated Project Name' } },
        headers: { 'Authorization' => "Bearer #{@admin_token}" },
        as: :json
    
    assert_response :success
    @project.reload
    assert_equal 'Updated Project Name', @project.name
    
    # Other admin cannot update project name
    original_name = @project.name
    
    put api_v1_project_url(@project),
        params: { project: { name: 'Other Admin Update' } },
        headers: { 'Authorization' => "Bearer #{@other_admin_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_name, @project.name
    
    # Project manager cannot update project name
    put api_v1_project_url(@project),
        params: { project: { name: 'Manager Update' } },
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_name, @project.name
    
    # Developer cannot update project name
    put api_v1_project_url(@project),
        params: { project: { name: 'Developer Update' } },
        headers: { 'Authorization' => "Bearer #{@developer_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_name, @project.name
  end
  
  test "only the admin that created a project can reassign its manager" do
    new_manager = create(:user, :project_manager)
    
    # Admin owner can reassign project manager
    put api_v1_project_url(@project),
        params: { project: { manager_id: new_manager.id } },
        headers: { 'Authorization' => "Bearer #{@admin_token}" },
        as: :json
    
    assert_response :success
    @project.reload
    assert_equal new_manager.id, @project.manager_id
    
    # Reset project manager for further tests
    @project.update(manager_id: @project_manager.id)
    
    # Other admin cannot reassign project manager
    original_manager_id = @project.manager_id
    other_manager = create(:user, :project_manager)
    
    put api_v1_project_url(@project),
        params: { project: { manager_id: other_manager.id } },
        headers: { 'Authorization' => "Bearer #{@other_admin_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_manager_id, @project.manager_id
    
    # Project manager cannot reassign project manager
    put api_v1_project_url(@project),
        params: { project: { manager_id: other_manager.id } },
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_manager_id, @project.manager_id
    
    # Developer cannot reassign project manager
    put api_v1_project_url(@project),
        params: { project: { manager_id: other_manager.id } },
        headers: { 'Authorization' => "Bearer #{@developer_token}" },
        as: :json
    
    assert_response :forbidden
    @project.reload
    assert_equal original_manager_id, @project.manager_id
  end
  
  test "only the admin that created a project can delete it" do
    # Create a new project for deletion test
    project_to_delete = create(:project, owner: @admin, manager: @project_manager)
    
    # Other admin cannot delete the project
    delete api_v1_project_url(project_to_delete),
           headers: { 'Authorization' => "Bearer #{@other_admin_token}" }
    
    assert_response :forbidden
    assert Project.exists?(project_to_delete.id)
    
    # Project manager cannot delete the project
    delete api_v1_project_url(project_to_delete),
           headers: { 'Authorization' => "Bearer #{@project_manager_token}" }
    
    assert_response :forbidden
    assert Project.exists?(project_to_delete.id)
    
    # Developer cannot delete the project
    delete api_v1_project_url(project_to_delete),
           headers: { 'Authorization' => "Bearer #{@developer_token}" }
    
    assert_response :forbidden
    assert Project.exists?(project_to_delete.id)
    
    # Admin owner can delete the project
    delete api_v1_project_url(project_to_delete),
           headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :no_content
    assert_not Project.exists?(project_to_delete.id)
  end
  
  test "when a project is deleted, all its tasks are deleted as well" do
    # Create a project with associated tasks
    project_with_tasks = create(:project, owner: @admin, manager: @project_manager)
    task1 = create(:task, project: project_with_tasks, assignee: @developer)
    task2 = create(:task, project: project_with_tasks, assignee: @developer)
    
    # Store task IDs for later verification
    task_ids = [task1.id, task2.id]
    
    # Admin owner deletes the project
    delete api_v1_project_url(project_with_tasks),
           headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :no_content
    
    # Verify project was deleted
    assert_not Project.exists?(project_with_tasks.id)
    
    # Verify associated tasks were also deleted
    task_ids.each do |task_id|
      assert_not Task.exists?(task_id)
    end
  end
  
  private
  
  def generate_token_for(user)
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end 