class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :manager, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :projects, :name, unique: true
  end
end
