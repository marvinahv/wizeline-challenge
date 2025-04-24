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
        
        # Admin can delete only projects they own
        can :destroy, Project, owner_id: user.id
        
        # Admin can see stats only for projects they own
        can :stats, Project, owner_id: user.id
      end
      
      # Project managers can manage tasks within their projects
      if user.role == 'project_manager'
        # Use simple conditions instead of blocks when possible to prevent N+1 queries
        can :manage_tasks, Project, manager_id: user.id
        
        # For task operations that depend on the project's manager, use a hash condition
        # to let CanCanCan optimize the query
        can [:create, :update, :destroy], Task, project: { manager_id: user.id }
        
        # But project managers cannot update the status of tasks
        cannot :update_status, Task
      end
      
      # Developers can view and update their assigned tasks
      if user.role == 'developer'
        # Use a simpler condition to avoid a block that might cause N+1 queries
        # Can view tasks in their projects
        can :read, Task, project: { tasks: { assignee_id: user.id } }
        
        # Developers can update status of tasks assigned to them
        can :update_status, Task, assignee_id: user.id
      end
    end
  end
end
