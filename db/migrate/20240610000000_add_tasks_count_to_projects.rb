class AddTasksCountToProjects < ActiveRecord::Migration[8.0]
  def up
    add_column :projects, :tasks_count, :integer, default: 0, null: false
    
    # Initialize counter cache
    Project.find_each do |project|
      Project.reset_counters(project.id, :tasks)
    end
  end

  def down
    remove_column :projects, :tasks_count
  end
end 