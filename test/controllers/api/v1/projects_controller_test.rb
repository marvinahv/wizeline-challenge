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
  
  private
  
  def generate_token_for(user)
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end 