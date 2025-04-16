module Api
  module V1
    class TasksController < BaseController
      before_action :authenticate_user!
      before_action :set_project, only: [:index, :create]
      before_action :set_task, only: [:show, :update, :destroy, :update_status]
      
      # GET /api/v1/projects/:project_id/tasks
      def index
        authorize! :read, @project
        @tasks = @project.tasks
        render json: @tasks
      end
      
      # POST /api/v1/projects/:project_id/tasks
      def create
        @task = @project.tasks.build(task_params)
        authorize! :create, @task
        
        if @task.save
          render json: @task, status: :created
        else
          render json: { errors: @task.errors }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/tasks/:id
      def show
        authorize! :read, @task
        render json: @task
      end
      
      # PUT /api/v1/tasks/:id
      def update
        authorize! :update, @task
        
        if @task.update(task_params)
          render json: @task
        else
          render json: { errors: @task.errors }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/tasks/:id
      def destroy
        authorize! :destroy, @task
        
        @task.destroy
        head :no_content
      end
      
      # PUT /api/v1/tasks/:id/status
      def update_status
        authorize! :update_status, @task
        
        if @task.update(status: params[:status])
          render json: @task
        else
          render json: { errors: @task.errors }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_project
        @project = Project.find(params[:project_id])
      end
      
      def set_task
        @task = Task.find(params[:id])
      end
      
      def task_params
        params.require(:task).permit(:description, :assignee_id)
      end
      
      # Handle CanCan authorization errors
      rescue_from CanCan::AccessDenied do |exception|
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end 