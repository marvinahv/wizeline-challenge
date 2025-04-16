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
      end
      
      # Developers don't have any special project permissions
      # Just leaving this here as a placeholder for future permissions
      if user.role == 'developer'
        # No special project permissions at this time
      end
    end
  end
end
