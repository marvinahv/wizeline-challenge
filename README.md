# Project Management API

A Rails API for managing projects and tasks with role-based access control.

## Tech Stack

- **Ruby**: 3.2.7
- **Rails**: 8.0.2
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Token)
- **Authorization**: CanCanCan
- **Testing**: Minitest, FactoryBot
- **API Framework**: Rails API-only mode

## Project Progress

The project has been developed using Test-Driven Development (TDD) methodology, with the following key milestones:

1. **Setup & Authentication**
   - Rails 8 API application with PostgreSQL
   - User model with secure authentication
   - JWT token generation for API access
   - Enhanced password security requirements

2. **Authorization & Project Management**
   - Role-based permissions using CanCanCan
   - Project creation and management for admins
   - Project ownership and access restrictions

3. **Task Management**
   - Task CRUD operations
   - Role-specific task permissions
   - Task status management

4. **API Enhancements**
   - User-specific project views with sorting
   - Role-based task listing with sorting

For a detailed development log, see `log.md`.

## Features

Based on our controller tests, the application provides the following features:

### Projects

- Admins can create new projects
- Admins can see all their created projects sorted by creation date (newest first)
- Only the admin that created a project can update its name
- Only the admin that created a project can reassign its manager
- Only the admin that created a project can delete it
- Project managers can see all their managed projects sorted by creation date
- Developers can see projects where they have assigned tasks

### Tasks

- Only the manager assigned to a project can create tasks
- Only the manager assigned to a project can edit tasks
- Only the manager assigned to a project can change a task's assignee
- Only the manager assigned to a project can delete tasks
- Only the assigned developer can update a task's status
- Project managers can see all tasks for projects they manage, sorted by creation date (oldest first)
- Developers can only see tasks assigned to them, sorted by creation date (oldest first)
- Admins can see all tasks for projects they own, sorted by creation date (oldest first)

## Business Rules

Based on our model tests, the application enforces the following rules:

### Users

- All users must have a name, email, password, and role
- Passwords must meet security requirements (8+ characters, uppercase, lowercase, number, symbol)
- Email addresses must be unique and valid
- User roles must be one of: admin, project_manager, or developer

### Projects

- Projects must have a name and a manager
- Project names must be unique
- Only admin users can own projects
- Only project manager users can manage projects
- Projects cascade delete their tasks when removed

### Tasks

- Tasks must belong to a project
- Tasks must have a description (no separate title field)
- Tasks must have an assigned developer
- Tasks have a status (todo, in_progress, done)
- Tasks default to "todo" status when created

## Running Tests

To run the test suite:

```bash
# Run all tests
rails test

# Run specific test files
rails test test/models/user_test.rb
rails test test/controllers/api/v1/projects_controller_test.rb
rails test test/controllers/api/v1/tasks_controller_test.rb

# Run specific test
rails test test/controllers/api/v1/projects_controller_test.rb:18
```

## Getting Started

1. Clone the repository
2. Install dependencies: `bundle install`
3. Set up the database: `rails db:create db:migrate`
4. Run the server: `rails server`

For more information about the API endpoints and authentication, see `API_DOCUMENTATION.md`.
