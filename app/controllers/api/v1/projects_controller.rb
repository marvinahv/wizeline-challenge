module Api
  module V1
    class ProjectsController < BaseController
      before_action :authenticate_user!
      before_action :set_project, only: [:show, :update, :destroy]
      
      # GET /api/v1/projects
      def index
        @projects = Project.all
        authorize! :read, Project
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
      
      private
      
      def set_project
        @project = Project.find(params[:id])
      end
      
      def project_params
        params.require(:project).permit(:name, :manager_id)
      end
      
      # Handle CanCan authorization errors
      rescue_from CanCan::AccessDenied do |exception|
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end 