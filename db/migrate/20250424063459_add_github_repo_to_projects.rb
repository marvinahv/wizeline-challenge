class AddGithubRepoToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :github_repo, :string
  end
end
