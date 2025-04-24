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
        
        # Sort by creation date (newest first) and eager load associations to prevent N+1 queries
        @projects = @projects.includes(:manager, :owner, :github_repository_datum).order(created_at: :desc)
        
        render json: @projects
      end
      
      # POST /api/v1/projects
      def create
        @project = Project.new(project_params)
        @project.owner = current_user
        authorize! :create, @project
        
        if @project.save
          # Schedule GitHub repo sync if a repo is provided
          if @project.github_repo.present? && current_user.github_connected?
            SyncGithubRepositoryJob.perform_later(@project.id)
          end
          
          render json: @project, status: :created
        else
          render json: { errors: @project.errors }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/projects/:id
      def show
        authorize! :read, @project
        # Eager load associations to prevent N+1 queries
        @project = Project.includes(:manager, :owner, :github_repository_datum, tasks: :assignee).find(@project.id)
        render json: @project
      end
      
      # PUT /api/v1/projects/:id
      def update
        authorize! :update, @project
        
        # Store the old GitHub repo for comparison
        old_github_repo = @project.github_repo
        
        if @project.update(project_params)
          # If GitHub repo has changed, schedule a sync job
          if @project.github_repo.present? && 
             @project.github_repo != old_github_repo && 
             current_user.github_connected?
            SyncGithubRepositoryJob.perform_later(@project.id)
          end
          
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
        
        # Use task_status_counts method to get all counts in a single query
        task_counts = @project.task_status_counts
        
        # Collect project statistics
        stats = {
          project: {
            id: @project.id,
            name: @project.name,
            tasks: {
              total: task_counts.values.sum,
              todo: task_counts['todo'] || 0,
              in_progress: task_counts['in_progress'] || 0,
              done: task_counts['done'] || 0
            },
            created_at: @project.created_at,
            updated_at: @project.updated_at
          },
          github: nil
        }
        
        # Add GitHub data if repository is linked
        if @project.github_repo.present?
          # Try to get cached GitHub data first
          repo_data = @project.github_repository_datum
          
          # If data exists and is recent (less than 24 hours old)
          if repo_data && repo_data.last_synced_at > 24.hours.ago
            # Use cached data
            stats[:github] = {
              name: repo_data.name,
              full_name: repo_data.full_name,
              description: repo_data.description,
              url: repo_data.url,
              stats: {
                stars: repo_data.stargazers_count,
                forks: repo_data.forks_count,
                open_issues: repo_data.open_issues_count
              },
              last_synced_at: repo_data.last_synced_at,
              created_at: repo_data.created_at,
              updated_at: repo_data.updated_at
            }
          elsif current_user.github_connected?
            # Schedule a background job to update the data for next time
            SyncGithubRepositoryJob.perform_later(@project.id)
            
            # For immediate response, fetch from API if user has GitHub token
            github_service = GithubService.new(current_user.github_token)
            repository = github_service.fetch_repository(@project.github_repo)
            
            if repository
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
              
              # Update the database in the background
              SyncGithubRepositoryJob.perform_later(@project.id)
            else
              stats[:github] = { error: "Repository data unavailable. It will be synchronized in the background." }
            end
          else
            stats[:github] = { error: "GitHub connection required to view repository data." }
          end
        end
        
        render json: stats
      end
      
      private
      
      def set_project
        # Eager load associations to prevent N+1 queries
        @project = Project.includes(:manager, :owner, :github_repository_datum).find(params[:id])
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