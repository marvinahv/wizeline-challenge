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

## LOG

The project has been developed using Test-Driven Development (TDD) methodology. Focused on solid functionality first and optimizations later. For a detailed development log, see `log.md`.

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
# Run all tests (segmentation faults, use:)
PARALLEL_WORKERS=1 rails test
```

You should see:

```bash
# Running:

SyncGithubRepositoryJobTest#test_job_handles_non-existent_project_gracefully = 0.06 s = .
SyncGithubRepositoryJobTest#test_job_syncs_GitHub_data_for_a_project = 0.06 s = .
SyncGithubRepositoryJobTest#test_job_handles_missing_GitHub_token_gracefully = 0.03 s = .
SyncGithubRepositoryJobTest#test_job_enqueues_with_project_ID = 0.01 s = .
SyncGithubRepositoryJobTest#test_job_schedules_updates_for_all_outdated_repositories = 0.03 s = .
Api::V1::ProjectsControllerTest#test_only_the_admin_that_created_a_project_can_reassign_its_manager = 0.11 s = .
Api::V1::ProjectsControllerTest#test_only_the_admin_that_created_a_project_can_update_its_name = 0.05 s = .
Api::V1::ProjectsControllerTest#test_admin_can_see_all_their_created_projects_sorted_by_creation_date,_newest_first = 0.03 s = .
Api::V1::ProjectsControllerTest#test_only_admins_can_create_new_projects = 0.04 s = .
Api::V1::ProjectsControllerTest#test_only_admin_who_owns_the_project_can_fetch_project_statistics = 0.08 s = .
Api::V1::ProjectsControllerTest#test_admin_can_access_stats_for_project_with_GitHub_repo_linked = 0.05 s = .
Api::V1::ProjectsControllerTest#test_developer_can_see_only_projects_where_they_have_assigned_tasks,_sorted_by_creation_date,_newest_first = 0.05 s = .
Api::V1::ProjectsControllerTest#test_when_a_project_is_deleted,_all_its_tasks_are_deleted_as_well = 0.04 s = .
Api::V1::ProjectsControllerTest#test_project_manager_can_see_all_their_managed_projects_sorted_by_creation_date,_newest_first = 0.05 s = .
Api::V1::ProjectsControllerTest#test_only_the_admin_that_created_a_project_can_delete_it = 0.05 s = .
Api::V1::AuthenticationControllerTest#test_should_not_authenticate_with_missing_credentials = 0.01 s = .
Api::V1::AuthenticationControllerTest#test_should_authenticate_user_with_valid_credentials = 0.01 s = .
Api::V1::AuthenticationControllerTest#test_should_not_authenticate_user_with_invalid_credentials = 0.01 s = .
ProjectTest#test_requires_name = 0.01 s = .
ProjectTest#test_requires_owner_to_be_admin = 0.02 s = .
ProjectTest#test_github_repo_can_be_nil = 0.01 s = .
ProjectTest#test_requires_a_project_manager = 0.01 s = .
ProjectTest#test_belongs_to_an_admin_owner = 0.01 s = .
ProjectTest#test_github_repo_can_be_blank = 0.01 s = .
ProjectTest#test_name_must_be_unique = 0.01 s = .
ProjectTest#test_belongs_to_a_project_manager = 0.01 s = .
ProjectTest#test_can_have_a_github_repository_associated = 0.01 s = .
ProjectTest#test_valid_project = 0.01 s = .
ProjectTest#test_requires_manager_to_be_a_project_manager_role = 0.02 s = .
ProjectTest#test_github_repo_format_is_valid = 0.01 s = .
GithubServiceTest#test_fetch_repository_handles_API_errors_gracefully = 0.01 s = .
GithubServiceTest#test_fetch_repository_returns_repository_data = 0.01 s = .
Api::V1::TasksControllerTest#test_only_the_assigned_developer_can_update_a_task's_status = 0.06 s = .
Api::V1::TasksControllerTest#test_only_the_manager_assigned_to_a_project_can_create_tasks = 0.05 s = .
Api::V1::TasksControllerTest#test_developer_can_only_see_tasks_assigned_to_them,_sorted_by_creation_date_oldest_first = 0.05 s = .
Api::V1::TasksControllerTest#test_admin_can_see_all_tasks_for_projects_they_own,_sorted_by_creation_date_oldest_first = 0.06 s = .
Api::V1::TasksControllerTest#test_only_the_manager_assigned_to_a_project_can_change_its_assignee_developer = 0.06 s = .
Api::V1::TasksControllerTest#test_project_manager_can_see_all_tasks_they_have_created_for_a_given_project,_sorted_by_creation_date_oldest_first = 0.06 s = .
Api::V1::TasksControllerTest#test_only_the_manager_assigned_to_a_project_can_edit_tasks = 0.06 s = .
Api::V1::TasksControllerTest#test_only_the_manager_assigned_to_a_project_can_delete_tasks = 0.05 s = .
TaskTest#test_default_status_is_todo = 0.02 s = .
TaskTest#test_requires_a_project = 0.02 s = .
TaskTest#test_belongs_to_a_project = 0.03 s = .
TaskTest#test_assignee_must_be_a_developer = 0.02 s = .
TaskTest#test_requires_a_description = 0.01 s = .
TaskTest#test_valid_task = 0.02 s = .
TaskTest#test_status_must_be_valid = 0.02 s = .
TaskTest#test_requires_an_assigned_developer = 0.02 s = .
UserTest#test_github_connected?_returns_false_when_github_token_is_nil = 0.01 s = .
UserTest#test_requires_email = 0.00 s = .
UserTest#test_accepts_valid_roles = 0.01 s = .
UserTest#test_requires_unique_email = 0.01 s = .
UserTest#test_password_must_be_at_least_8_characters = 0.00 s = .
UserTest#test_github_token_is_encrypted = 0.01 s = .
UserTest#test_requires_valid_email_format = 0.00 s = .
UserTest#test_generates_JWT_token = 0.01 s = .
UserTest#test_authenticates_with_valid_credentials = 0.01 s = .
UserTest#test_does_not_authenticate_with_invalid_credentials = 0.01 s = .
UserTest#test_github_connected?_returns_false_when_github_token_is_blank = 0.00 s = .
UserTest#test_requires_valid_role = 0.00 s = .
UserTest#test_creates_users_with_different_roles = 0.01 s = .
UserTest#test_valid_user = 0.00 s = .
UserTest#test_github_connected?_returns_true_when_github_token_is_present = 0.00 s = .
UserTest#test_password_must_include_uppercase,_lowercase,_number_and_symbol = 0.01 s = .
UserTest#test_requires_name = 0.00 s = .
UserTest#test_requires_password = 0.00 s = .
UserTest#test_generates_different_tokens_for_different_users = 0.01 s = .

Finished in 1.708615s, 39.2130 runs/s, 172.6545 assertions/s.
67 runs, 295 assertions, 0 failures, 0 errors, 0 skips
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
