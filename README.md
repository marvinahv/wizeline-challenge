# Project Management API

A Rails API for managing projects and tasks with role-based access control and GitHub integration.

## Tech Stack

- **Ruby**: 3.2.7
- **Rails**: 8.0.2
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Token)
- **Authorization**: CanCanCan
- **Testing**: Minitest, FactoryBot
- **API Framework**: Rails API-only mode
- **External APIs**: GitHub API integration
- **Background Processing**: Delayed Job

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

5. **GitHub Integration**
   - GitHub repository linking to projects
   - Secure token management with encryption
   - Background syncing of repository data
   - Project statistics with GitHub data

6. **Performance Optimizations**
   - N+1 query prevention with eager loading
   - Counter caches for efficient counting
   - Query optimizations with GROUP BY
   - Efficient association loading

For a detailed development log, see `log.md`.

## Features

### Projects

- Admins can create new projects
- Admins can see all their created projects sorted by creation date (newest first)
- Only the admin that created a project can update its name
- Only the admin that created a project can reassign its manager
- Only the admin that created a project can delete it
- Project managers can see all their managed projects sorted by creation date
- Developers can see projects where they have assigned tasks
- Projects can be linked to GitHub repositories
- Project statistics show task counts by status and GitHub repository data

### Tasks

- Only the manager assigned to a project can create tasks
- Only the manager assigned to a project can edit tasks
- Only the manager assigned to a project can change a task's assignee
- Only the manager assigned to a project can delete tasks
- Only the assigned developer can update a task's status
- Project managers can see all tasks for projects they manage, sorted by creation date (oldest first)
- Developers can only see tasks assigned to them, sorted by creation date (oldest first)
- Admins can see all tasks for projects they own, sorted by creation date (oldest first)
- Task counts are efficiently cached at the project level

### GitHub Integration

- Projects can be linked to GitHub repositories using the format `owner/repo`
- GitHub repository data is fetched and cached in the database
- GitHub data includes repository stars, forks, and open issues counts
- Data is automatically refreshed when older than 24 hours
- Background jobs handle GitHub API interactions asynchronously
- Secure storage of GitHub access tokens with encryption

## Performance Optimizations

The application includes various optimizations to ensure good performance at scale:

### N+1 Query Prevention

- Eager loading of associations to prevent N+1 queries
- Controllers use `includes` to fetch required associations in a single query
- Nested associations are loaded efficiently with deep includes

### Efficient Counting

- Counter caches track the number of tasks per project
- Task status counts use a single GROUP BY query instead of multiple count queries
- Scopes provide efficient query patterns for common operations

### Background Processing

- GitHub data synchronization runs in background jobs
- Jobs are retried with exponential backoff for rate limiting
- Error handling prevents job failures from affecting the user experience

### Authorization Optimizations

- CanCanCan rules are optimized to use hash conditions instead of blocks
- User authentication includes preloading of commonly accessed associations
- Efficient loading of user projects based on role

## Business Rules

Based on our model tests, the application enforces the following rules:

### Users

- All users must have a name, email, password, and role
- Passwords must meet security requirements (8+ characters, uppercase, lowercase, number, symbol)
- Email addresses must be unique and valid
- User roles must be one of: admin, project_manager, or developer
- Users can securely store GitHub access tokens (encrypted)

### Projects

- Projects must have a name and a manager
- Project names must be unique
- Only admin users can own projects
- Only project manager users can manage projects
- Projects cascade delete their tasks when removed
- Projects can be linked to GitHub repositories (optional)
- GitHub repository format must be valid (`owner/repository`)

### Tasks

- Tasks must belong to a project
- Tasks must have a description (no separate title field)
- Tasks must have an assigned developer
- Tasks have a status (todo, in_progress, done)
- Tasks default to "todo" status when created
- Task counts are efficiently managed with counter caches

## Architecture

The application follows a standard Rails architecture with some specific design patterns:

### Controllers

- API versioning (v1) for future-proofing
- Authentication via JWT tokens
- Authorization through CanCanCan
- JSON-based request/response cycle
- RESTful endpoints for all resources

### Models

- Role-based authorization rules
- Rich business logic validations
- Counter caches for performance
- Efficient scopes for common queries
- Secure password handling

### Services

- External API integrations abstracted into service objects
- GitHub API interaction via the `GithubService`
- Error handling and retries for external services

### Background Jobs

- Asynchronous processing for GitHub data synchronization
- Retry strategies for handling transient failures
- Scheduled jobs for periodic data updates

## Running Tests

To run the test suite:

```bash
# Run all tests
rails test

# If you encounter segmentation faults, use:
PARALLEL_WORKERS=1 rails test

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
5. Start the background job processor: `bin/delayed_job start`

For more information about the API endpoints and authentication, see `API_DOCUMENTATION.md`.

## Development Monitoring

The application includes development tools to help identify potential performance issues:

- N+1 query detection in the BaseController
- SQL query logging for requests with excessive database queries
- Development logging of GitHub API interactions

## Code Challenge Assessment

A comprehensive analysis of how this codebase fulfills the requirements of the Wizeline Technical Test for Ruby on Rails Senior Backend Developer position is available in the `challenge_report.md` file. The report includes:

- Detailed assessment of core features implementation
- Analysis of technical requirements fulfillment
- Evaluation against the provided criteria
- Key strengths and areas for improvement

Review this document for insights into the project's compliance with the code challenge specifications.
