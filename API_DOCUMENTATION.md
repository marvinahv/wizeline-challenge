# API Documentation

This document provides comprehensive documentation for the Project Management API, including authentication methods and available endpoints.

## Authentication

The API uses JWT (JSON Web Token) for authentication. To access protected endpoints, you need to include the token in the `Authorization` header of your requests.

### Login and Token Generation

**Endpoint:** `POST /api/v1/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecureP@ss123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@example.com",
    "role": "admin"
  }
}
```

### Using the Token

Include the token in the `Authorization` header of your requests:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

## Password Requirements

When creating or updating user passwords, they must meet the following requirements:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

## Endpoints

### Projects

#### List Projects

**Endpoint:** `GET /api/v1/projects`

**Authentication:** Required

**Description:** Returns a list of projects based on the user's role:
- Admins see projects they own, sorted by creation date (newest first)
- Project managers see projects they manage, sorted by creation date (newest first)
- Developers see projects where they have assigned tasks, sorted by creation date (newest first)

**Response:**
```json
[
  {
    "id": 1,
    "name": "Project A",
    "owner_id": 1,
    "manager_id": 2,
    "github_repo": "octocat/Hello-World",
    "tasks_count": 5,
    "created_at": "2023-04-01T12:00:00Z",
    "updated_at": "2023-04-01T12:00:00Z"
  },
  {
    "id": 2,
    "name": "Project B",
    "owner_id": 1,
    "manager_id": 2,
    "github_repo": null,
    "tasks_count": 2,
    "created_at": "2023-03-15T09:30:00Z",
    "updated_at": "2023-03-15T09:30:00Z"
  }
]
```

**Performance Note:** This endpoint uses eager loading to efficiently retrieve associated data for each project, avoiding N+1 queries.

#### Get Project Details

**Endpoint:** `GET /api/v1/projects/:id`

**Authentication:** Required

**Description:** Returns details for a specific project

**Response:**
```json
{
  "id": 1,
  "name": "Project A",
  "owner_id": 1,
  "manager_id": 2,
  "github_repo": "octocat/Hello-World",
  "tasks_count": 5,
  "created_at": "2023-04-01T12:00:00Z",
  "updated_at": "2023-04-01T12:00:00Z"
}
```

**Performance Note:** This endpoint uses eager loading to retrieve the project with its associated tasks, owner, and manager data in a single query.

#### Get Project Statistics

**Endpoint:** `GET /api/v1/projects/:id/stats`

**Authentication:** Required

**Authorization:** Only the admin who created the project can access its statistics

**Description:** Returns detailed statistics about a project, including task counts by status and GitHub repository data if available.

**Response for project with GitHub repository:**
```json
{
  "project": {
    "id": 1,
    "name": "Project A",
    "tasks": {
      "total": 5,
      "todo": 2,
      "in_progress": 2,
      "done": 1
    },
    "created_at": "2023-04-01T12:00:00Z",
    "updated_at": "2023-04-01T12:00:00Z"
  },
  "github": {
    "name": "Hello-World",
    "full_name": "octocat/Hello-World",
    "description": "This is a sample repository",
    "url": "https://github.com/octocat/Hello-World",
    "stats": {
      "stars": 80,
      "forks": 20,
      "open_issues": 5
    },
    "last_synced_at": "2023-04-15T13:45:22Z",
    "created_at": "2023-04-15T13:45:22Z",
    "updated_at": "2023-04-15T13:45:22Z"
  }
}
```

**Response for project without GitHub repository:**
```json
{
  "project": {
    "id": 2,
    "name": "Project B",
    "tasks": {
      "total": 3,
      "todo": 1,
      "in_progress": 1,
      "done": 1
    },
    "created_at": "2023-03-15T09:30:00Z",
    "updated_at": "2023-03-15T09:30:00Z"
  },
  "github": null
}
```

**Performance Note:** This endpoint efficiently calculates task counts using a single database query with GROUP BY, and uses data cached in the database for GitHub repository information when possible.

#### Create Project

**Endpoint:** `POST /api/v1/projects`

**Authentication:** Required

**Authorization:** Only admins can create projects

**Request Body:**
```json
{
  "project": {
    "name": "New Project",
    "manager_id": 2,
    "github_repo": "octocat/Hello-World"
  }
}
```

**Response:**
```json
{
  "id": 3,
  "name": "New Project",
  "owner_id": 1,
  "manager_id": 2,
  "github_repo": "octocat/Hello-World",
  "tasks_count": 0,
  "created_at": "2023-04-16T15:30:00Z",
  "updated_at": "2023-04-16T15:30:00Z"
}
```

**Notes:**
- `github_repo` is optional but if provided must follow the format `owner/repository`
- `github_repo` allows linking the project to a GitHub repository for integration features
- When a GitHub repository is linked, a background job is automatically scheduled to fetch and cache repository data

#### Update Project

**Endpoint:** `PUT /api/v1/projects/:id`

**Authentication:** Required

**Authorization:** Only the admin who created the project can update it

**Request Body:**
```json
{
  "project": {
    "name": "Updated Project Name",
    "manager_id": 3,
    "github_repo": "octocat/Updated-Repo"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "name": "Updated Project Name",
  "owner_id": 1,
  "manager_id": 3,
  "github_repo": "octocat/Updated-Repo",
  "tasks_count": 5,
  "created_at": "2023-04-01T12:00:00Z",
  "updated_at": "2023-04-16T16:15:00Z"
}
```

**Notes:**
- If the GitHub repository is changed, a background job is automatically scheduled to fetch updated repository data

#### Delete Project

**Endpoint:** `DELETE /api/v1/projects/:id`

**Authentication:** Required

**Authorization:** Only the admin who created the project can delete it

**Response:** Status 204 No Content

**Notes:**
- Deleting a project will also delete all associated tasks (cascade delete)

### Tasks

#### List Tasks for a Project

**Endpoint:** `GET /api/v1/projects/:project_id/tasks`

**Authentication:** Required

**Description:** Returns a list of tasks for a specific project based on the user's role:
- Project managers see all tasks for projects they manage, sorted by creation date (oldest first)
- Developers see only tasks assigned to them, sorted by creation date (oldest first)
- Admins see all tasks for projects they own, sorted by creation date (oldest first)

**Response:**
```json
[
  {
    "id": 1,
    "description": "Task 1",
    "status": "todo",
    "project_id": 1,
    "assignee_id": 3,
    "created_at": "2023-04-01T14:00:00Z",
    "updated_at": "2023-04-01T14:00:00Z"
  },
  {
    "id": 2,
    "description": "Task 2",
    "status": "in_progress",
    "project_id": 1,
    "assignee_id": 3,
    "created_at": "2023-04-02T09:15:00Z",
    "updated_at": "2023-04-03T11:30:00Z"
  }
]
```

**Performance Note:** This endpoint uses eager loading to efficiently retrieve associated data for each task, avoiding N+1 queries.

#### Get Task Details

**Endpoint:** `GET /api/v1/tasks/:id`

**Authentication:** Required

**Description:** Returns details for a specific task

**Response:**
```json
{
  "id": 1,
  "description": "Task 1",
  "status": "todo",
  "project_id": 1,
  "assignee_id": 3,
  "created_at": "2023-04-01T14:00:00Z",
  "updated_at": "2023-04-01T14:00:00Z"
}
```

**Performance Note:** This endpoint uses eager loading to retrieve the task with its project, assignee, and other related data in a single query.

#### Create Task

**Endpoint:** `POST /api/v1/projects/:project_id/tasks`

**Authentication:** Required

**Authorization:** Only the manager assigned to the project can create tasks

**Request Body:**
```json
{
  "task": {
    "description": "New Task",
    "assignee_id": 3
  }
}
```

**Response:**
```json
{
  "id": 3,
  "description": "New Task",
  "status": "todo",
  "project_id": 1,
  "assignee_id": 3,
  "created_at": "2023-04-16T17:00:00Z",
  "updated_at": "2023-04-16T17:00:00Z"
}
```

**Notes:**
- Tasks are automatically assigned the status "todo" when created
- The assignee must be a user with the "developer" role
- Creating a task automatically updates the project's task count via counter cache

#### Update Task

**Endpoint:** `PUT /api/v1/tasks/:id`

**Authentication:** Required

**Authorization:** Only the manager assigned to the project can update task descriptions and assignees

**Request Body:**
```json
{
  "task": {
    "description": "Updated Task Description",
    "assignee_id": 4
  }
}
```

**Response:**
```json
{
  "id": 1,
  "description": "Updated Task Description",
  "status": "todo",
  "project_id": 1,
  "assignee_id": 4,
  "created_at": "2023-04-01T14:00:00Z",
  "updated_at": "2023-04-16T17:30:00Z"
}
```

#### Update Task Status

**Endpoint:** `PUT /api/v1/tasks/:id/status`

**Authentication:** Required

**Authorization:** Only the developer assigned to the task can update its status

**Request Body:**
```json
{
  "status": "in_progress"
}
```

**Response:**
```json
{
  "id": 1,
  "description": "Task 1",
  "status": "in_progress",
  "project_id": 1,
  "assignee_id": 3,
  "created_at": "2023-04-01T14:00:00Z",
  "updated_at": "2023-04-16T18:00:00Z"
}
```

**Notes:**
- Status must be one of: "todo", "in_progress", or "done"

#### Delete Task

**Endpoint:** `DELETE /api/v1/tasks/:id`

**Authentication:** Required

**Authorization:** Only the manager assigned to the project can delete tasks

**Response:** Status 204 No Content

**Notes:**
- Deleting a task automatically updates the project's task count via counter cache

## GitHub Integration

The API integrates with GitHub to provide repository data for projects. This is handled automatically when:
- A project is created with a valid `github_repo` value
- A project's `github_repo` value is updated
- The stats endpoint is accessed for a project with a GitHub repository

GitHub data is cached in the database for 24 hours to improve performance and avoid GitHub API rate limits. If data is older than 24 hours, it will be refreshed in the background when the stats endpoint is accessed.

## Error Responses

### Authentication Errors

**Status:** 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

### Authorization Errors

**Status:** 403 Forbidden
```json
{
  "error": "Forbidden"
}
```

### Validation Errors

**Status:** 422 Unprocessable Entity
```json
{
  "errors": {
    "name": ["can't be blank"],
    "email": ["has already been taken"]
  }
}
```

### Not Found Errors

**Status:** 404 Not Found
```json
{
  "error": "Record not found"
}
```

## Performance Considerations

The API is optimized for performance with the following features:
- Eager loading of associated records to prevent N+1 query issues
- Counter caches for efficient counting of associated records
- Group queries for efficient aggregation of task statistics
- Background processing for GitHub API integration
- Database caching of GitHub repository data to reduce API calls 