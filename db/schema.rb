# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_24_175000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "github_repository_data", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "full_name", null: false
    t.string "name", null: false
    t.text "description"
    t.string "url", null: false
    t.integer "stargazers_count", default: 0
    t.integer "forks_count", default: 0
    t.integer "open_issues_count", default: 0
    t.datetime "last_synced_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "full_name"], name: "index_github_repository_data_on_project_id_and_full_name", unique: true
    t.index ["project_id"], name: "index_github_repository_data_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "owner_id", null: false
    t.bigint "manager_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "github_repo"
    t.index ["manager_id"], name: "index_projects_on_manager_id"
    t.index ["name"], name: "index_projects_on_name", unique: true
    t.index ["owner_id"], name: "index_projects_on_owner_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.text "description", null: false
    t.string "status", default: "todo", null: false
    t.bigint "project_id", null: false
    t.bigint "assignee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "github_token"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "github_repository_data", "projects"
  add_foreign_key "projects", "users", column: "manager_id"
  add_foreign_key "projects", "users", column: "owner_id"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "users", column: "assignee_id"
end
