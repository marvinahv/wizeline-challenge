class CreateGithubRepositoryData < ActiveRecord::Migration[8.0]
  def change
    create_table :github_repository_data do |t|
      t.references :project, null: false, foreign_key: true
      t.string :full_name, null: false
      t.string :name, null: false
      t.text :description
      t.string :url, null: false
      t.integer :stargazers_count, default: 0
      t.integer :forks_count, default: 0
      t.integer :open_issues_count, default: 0
      t.datetime :last_synced_at, null: false

      t.timestamps
    end
    
    add_index :github_repository_data, [:project_id, :full_name], unique: true
  end
end 