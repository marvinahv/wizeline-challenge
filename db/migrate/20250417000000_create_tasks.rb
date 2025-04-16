class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.text :description, null: false
      t.string :status, default: 'todo', null: false
      t.references :project, null: false, foreign_key: true
      t.references :assignee, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end 