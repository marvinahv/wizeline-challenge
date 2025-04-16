# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Ensure user is provided since we don't support guest access
    raise ArgumentError, 'User must be provided' if user.nil?
    
    # Everyone can view projects
    can :read, Project
    
    if user.persisted?
      # Admin users can perform specific actions on projects they own
      if user.role == 'admin'
        # Admin can create projects
        can :create, Project
        
        # Admin can update only projects they own
        can :update, Project, owner_id: user.id
        
        # Admin can change name only for projects they own
        can :update_name, Project, owner_id: user.id
        
        # Admin can change manager only for projects they own
        can :update_manager, Project, owner_id: user.id
      end
      
      # Project managers can manage tasks within their projects
      if user.role == 'project_manager'
        can :manage_tasks, Project, manager_id: user.id
        
        # Project managers can create tasks for projects they manage
        can :create, Task do |task|
          task.project.manager_id == user.id
        end
        
        # Project managers can update tasks for projects they manage
        can :update, Task do |task|
          task.project.manager_id == user.id
        end
        
        # Project managers can delete tasks for projects they manage
        can :destroy, Task do |task|
          task.project.manager_id == user.id
        end
        
        # But project managers cannot update the status of tasks
        cannot :update_status, Task
      end
      
      # Developers can view and update their assigned tasks
      if user.role == 'developer'
        # Developers can view all tasks in projects they're assigned to
        can :read, Task do |task|
          task.project.tasks.exists?(assignee_id: user.id)
        end
        
        # Developers can update status of tasks assigned to them
        can :update_status, Task, assignee_id: user.id
      end
    end
  end
end
