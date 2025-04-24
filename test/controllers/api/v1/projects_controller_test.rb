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
  
  test "admin can see all their created projects sorted by creation date, newest first" do
    # Clear existing projects for a clean test
    Project.delete_all
    
    # Create projects with specific creation dates
    oldest = create(:project, name: "Oldest Project", owner: @admin, manager: @project_manager, created_at: 3.days.ago)
    middle = create(:project, name: "Middle Project", owner: @admin, manager: @project_manager, created_at: 2.days.ago)
    newest = create(:project, name: "Newest Project", owner: @admin, manager: @project_manager, created_at: 1.day.ago)
    
    # Create a project owned by another admin (should not appear in results)
    other_admin_project = create(:project, name: "Other Admin Project", owner: @other_admin, manager: @project_manager)
    
    # Test that admin sees their projects sorted by creation date (newest first)
    get api_v1_projects_url,
        headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :success
    
    # Verify only the admin's projects are returned
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    project_ids = json_response.map { |p| p['id'] }
    assert_equal [newest.id, middle.id, oldest.id], project_ids
    
    # Verify no other admin's projects are included
    assert_not_includes project_ids, other_admin_project.id
  end
  
  test "project manager can see all their managed projects sorted by creation date, newest first" do
    # Clear existing projects for a clean test
    Project.delete_all
    
    # Create an additional project manager
    other_manager = create(:user, :project_manager)
    other_manager_token = generate_token_for(other_manager)
    
    # Create projects managed by our project manager with specific creation dates
    oldest = create(:project, name: "Oldest PM Project", owner: @admin, manager: @project_manager, created_at: 3.days.ago)
    middle = create(:project, name: "Middle PM Project", owner: @admin, manager: @project_manager, created_at: 2.days.ago)
    newest = create(:project, name: "Newest PM Project", owner: @admin, manager: @project_manager, created_at: 1.day.ago)
    
    # Create a project managed by another project manager (should not appear in results)
    other_manager_project = create(:project, name: "Other Manager Project", owner: @admin, manager: other_manager)
    
    # Test that project manager sees only their managed projects sorted by creation date (newest first)
    get api_v1_projects_url,
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" }
    
    assert_response :success
    
    # Verify only the projects managed by this project manager are returned
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    project_ids = json_response.map { |p| p['id'] }
    assert_equal [newest.id, middle.id, oldest.id], project_ids
    
    # Verify no projects managed by other project managers are included
    assert_not_includes project_ids, other_manager_project.id
  end
  
  test "developer can see only projects where they have assigned tasks, sorted by creation date, newest first" do
    # Clear existing projects for a clean test
    Project.delete_all
    
    # Create an additional developer
    other_developer = create(:user, :developer)
    
    # Create projects with tasks assigned to our developer
    project1 = create(:project, name: "Project 1", owner: @admin, manager: @project_manager, created_at: 3.days.ago)
    project2 = create(:project, name: "Project 2", owner: @admin, manager: @project_manager, created_at: 2.days.ago)
    project3 = create(:project, name: "Project 3", owner: @admin, manager: @project_manager, created_at: 1.day.ago)
    
    # Create a project with tasks assigned to another developer (should not appear in results)
    project4 = create(:project, name: "Project 4", owner: @admin, manager: @project_manager)
    
    # Assign tasks to our developer in projects 1 and 3 (but not 2)
    create(:task, project: project1, assignee: @developer)
    create(:task, project: project3, assignee: @developer)
    
    # Assign a task to the other developer in project 4
    create(:task, project: project4, assignee: other_developer)
    
    # Also assign a task to the other developer in project 1 (our developer should still see this project)
    create(:task, project: project1, assignee: other_developer)
    
    # Test that developer sees only projects where they have assigned tasks
    get api_v1_projects_url,
        headers: { 'Authorization' => "Bearer #{@developer_token}" }
    
    assert_response :success
    
    # Verify only the projects with tasks assigned to this developer are returned
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response.length
    
    # Verify they are sorted by creation date (newest first)
    project_ids = json_response.map { |p| p['id'] }
    assert_equal [project3.id, project1.id], project_ids
    
    # Verify projects without tasks assigned to this developer are not included
    assert_not_includes project_ids, project2.id
    assert_not_includes project_ids, project4.id
  end
  
  test "only admin who owns the project can fetch project statistics" do
    # Create a project without GitHub repo
    project = create(:project, owner: @admin, manager: @project_manager)
    
    # Create some tasks in different statuses
    create(:task, project: project, assignee: @developer, status: 'todo')
    create(:task, project: project, assignee: @developer, status: 'todo')
    create(:task, project: project, assignee: @developer, status: 'in_progress')
    create(:task, project: project, assignee: @developer, status: 'done')
    
    # Admin owner can access stats
    get stats_api_v1_project_path(project),
        headers: { 'Authorization' => "Bearer #{@admin_token}" }
    
    assert_response :success
    
    # Parse and check the response
    json_response = JSON.parse(response.body)
    
    # Check project stats
    assert_equal project.id, json_response["project"]["id"]
    assert_equal project.name, json_response["project"]["name"]
    assert_equal 4, json_response["project"]["tasks"]["total"]
    assert_equal 2, json_response["project"]["tasks"]["todo"]
    assert_equal 1, json_response["project"]["tasks"]["in_progress"]
    assert_equal 1, json_response["project"]["tasks"]["done"]
    
    # GitHub data should be nil since no repo is linked
    assert_nil json_response["github"]
    
    # Other admin cannot access stats
    get stats_api_v1_project_path(project),
        headers: { 'Authorization' => "Bearer #{@other_admin_token}" }
    
    assert_response :forbidden
    
    # Project manager cannot access stats
    get stats_api_v1_project_path(project),
        headers: { 'Authorization' => "Bearer #{@project_manager_token}" }
    
    assert_response :forbidden
    
    # Developer cannot access stats
    get stats_api_v1_project_path(project),
        headers: { 'Authorization' => "Bearer #{@developer_token}" }
    
    assert_response :forbidden
  end
  
  test "admin can access stats for project with GitHub repo linked" do
    # Create a GitHub-connected user for testing
    github_admin = create(:user, :admin, :with_github)
    github_admin_token = generate_token_for(github_admin)
    
    # Create a project with GitHub repo
    project = create(:project, 
                    owner: github_admin, 
                    manager: @project_manager, 
                    github_repo: "octocat/Hello-World")
    
    # Create some tasks
    create(:task, project: project, assignee: @developer, status: 'todo')
    create(:task, project: project, assignee: @developer, status: 'done')
    
    # Test with VCR to mock the GitHub API
    VCR.use_cassette("github/stats_with_repo") do
      get stats_api_v1_project_path(project),
          headers: { 'Authorization' => "Bearer #{github_admin_token}" }
      
      assert_response :success
      
      # Parse and check the response
      json_response = JSON.parse(response.body)
      
      # Check project stats
      assert_equal project.id, json_response["project"]["id"]
      assert_equal project.name, json_response["project"]["name"]
      assert_equal 2, json_response["project"]["tasks"]["total"]
      assert_equal 1, json_response["project"]["tasks"]["todo"]
      assert_equal 0, json_response["project"]["tasks"]["in_progress"]
      assert_equal 1, json_response["project"]["tasks"]["done"]
      
      # GitHub data should be present
      assert_not_nil json_response["github"]
      assert_equal "Hello-World", json_response["github"]["name"]
      assert_equal "octocat/Hello-World", json_response["github"]["full_name"]
      
      # Stats section should be present with basic repo metrics
      assert json_response["github"]["stats"].has_key?("stars")
      assert json_response["github"]["stats"].has_key?("forks")
      assert json_response["github"]["stats"].has_key?("open_issues")
    end
  end
  
  private
  
  def generate_token_for(user)
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end 