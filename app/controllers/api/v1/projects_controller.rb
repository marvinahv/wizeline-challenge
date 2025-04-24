module Api
  module V1
    class ProjectsController < BaseController
      before_action :authenticate_user!
      before_action :set_project, only: [:show, :update, :destroy, :stats]
      
      # GET /api/v1/projects
      def index
        authorize! :read, Project
        
        # Filter projects based on user role
        if user_is_admin?
          # Admin sees only projects they own
          @projects = Project.where(owner: current_user)
        elsif user_is_project_manager?
          # Project manager sees only projects they manage
          @projects = Project.where(manager: current_user)
        else
          # Developer sees projects where they have assigned tasks
          @projects = Project.joins(:tasks).where(tasks: { assignee_id: current_user.id }).distinct
        end
        
        # Sort by creation date (newest first)
        @projects = @projects.order(created_at: :desc)
        
        render json: @projects
      end
      
      # POST /api/v1/projects
      def create
        @project = Project.new(project_params)
        @project.owner = current_user
        authorize! :create, @project
        
        if @project.save
          render json: @project, status: :created
        else
          render json: { errors: @project.errors }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/projects/:id
      def show
        authorize! :read, @project
        render json: @project
      end
      
      # PUT /api/v1/projects/:id
      def update
        authorize! :update, @project
        
        if @project.update(project_params)
          render json: @project
        else
          render json: { errors: @project.errors }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/projects/:id
      def destroy
        authorize! :destroy, @project
        
        @project.destroy
        head :no_content
      end
      
      # GET /api/v1/projects/:id/stats
      def stats
        authorize! :stats, @project
        
        # Collect project statistics
        stats = {
          project: {
            id: @project.id,
            name: @project.name,
            tasks: {
              total: @project.tasks.count,
              todo: @project.tasks.where(status: 'todo').count,
              in_progress: @project.tasks.where(status: 'in_progress').count,
              done: @project.tasks.where(status: 'done').count
            },
            created_at: @project.created_at,
            updated_at: @project.updated_at
          },
          github: nil
        }
        
        # Add GitHub data if repository is linked and user has a GitHub token
        if @project.github_repo.present? && current_user.github_connected?
          github_service = GithubService.new(current_user.github_token)
          
          # Fetch repository data
          repository = github_service.fetch_repository(@project.github_repo)
          
          if repository
            # Add GitHub data to response
            stats[:github] = {
              name: repository.name,
              full_name: repository.full_name,
              description: repository.description,
              url: repository.html_url,
              stats: {
                stars: repository.stargazers_count,
                forks: repository.forks_count,
                open_issues: repository.open_issues_count
              },
              created_at: repository.created_at,
              updated_at: repository.updated_at
            }
          end
        end
        
        render json: stats
      end
      
      private
      
      def set_project
        @project = Project.find(params[:id])
      end
      
      def project_params
        params.require(:project).permit(:name, :manager_id, :github_repo)
      end
      
      def user_is_admin?
        current_user.role == 'admin'
      end
      
      def user_is_project_manager?
        current_user.role == 'project_manager'
      end
      
      # Handle CanCan authorization errors
      rescue_from CanCan::AccessDenied do |exception|
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end 