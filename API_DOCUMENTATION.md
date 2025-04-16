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
    "created_at": "2023-04-01T12:00:00Z",
    "updated_at": "2023-04-01T12:00:00Z"
  },
  {
    "id": 2,
    "name": "Project B",
    "owner_id": 1,
    "manager_id": 2,
    "created_at": "2023-03-15T09:30:00Z",
    "updated_at": "2023-03-15T09:30:00Z"
  }
]
```

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
  "created_at": "2023-04-01T12:00:00Z",
  "updated_at": "2023-04-01T12:00:00Z"
}
```

#### Create Project

**Endpoint:** `POST /api/v1/projects`

**Authentication:** Required

**Authorization:** Only admins can create projects

**Request Body:**
```json
{
  "project": {
    "name": "New Project",
    "manager_id": 2
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
  "created_at": "2023-04-16T15:30:00Z",
  "updated_at": "2023-04-16T15:30:00Z"
}
```

#### Update Project

**Endpoint:** `PUT /api/v1/projects/:id`

**Authentication:** Required

**Authorization:** Only the admin who created the project can update it

**Request Body:**
```json
{
  "project": {
    "name": "Updated Project Name",
    "manager_id": 3
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
  "created_at": "2023-04-01T12:00:00Z",
  "updated_at": "2023-04-16T16:15:00Z"
}
```

#### Delete Project

**Endpoint:** `DELETE /api/v1/projects/:id`

**Authentication:** Required

**Authorization:** Only the admin who created the project can delete it

**Response:** Status 204 No Content

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

#### Delete Task

**Endpoint:** `DELETE /api/v1/tasks/:id`

**Authentication:** Required

**Authorization:** Only the manager assigned to the project can delete tasks

**Response:** Status 204 No Content

## Error Responses

### Authentication Errors

**Status:** 401 Unauthorized
```json
{
  "error": "Not authenticated"
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