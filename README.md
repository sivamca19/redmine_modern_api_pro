# Redmine Modern API Pro Plugin

**Extends and modernizes Redmine’s API for mobile and third-party integrations.**

This plugin provides a modern, RESTful API for Redmine, designed to be used with mobile applications and other third-party integrations. It includes a robust authentication system, and provides endpoints for accessing and managing projects, issues, and other Redmine data.

## Features

*   **Token-based Authentication:** Secure your API with API tokens.
*   **Dashboard API:** Get a summary of your Redmine activity.
*   **Projects API:** Manage your Redmine projects.
*   **Swagger Documentation:** A complete Swagger/OpenAPI documentation for the API.

## Installation

1.  Clone this repository into your Redmine `plugins` directory:
    ```bash
    git clone https://github.com/sivamca19/redmine_modern_api_pro.git plugins/redmine_modern_api_pro
    ```
2.  Install the required gems:
    ```bash
    bundle install
    ```
3.  Restart your Redmine server.

## API Documentation

The API is documented in Swagger/OpenAPI format. You can access the Swagger UI at `/api-docs`.

### Authentication

#### `POST /api/v1/login`

User login. Returns an API token to be used for subsequent requests.

**Parameters:**

*   `username` (string, required): The user's username.
*   `password` (string, required): The user's password.

**Responses:**

*   `200`: Successful login. Returns an API token and user information.
*   `400`: Missing credentials.
*   `401`: Invalid username or password.

#### `DELETE /api/v1/logout`

User logout. Invalidates the API token.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Responses:**

*   `200`: Successful logout.
*   `401`: Invalid or missing API token.

### Dashboard

#### `GET /api/v1/dashboard`

Get user dashboard. Returns user's personal dashboard with summary stats, issues, and recent activity.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Responses:**

*   `200`: Dashboard loaded successfully.
*   `401`: Unauthorized.

#### `GET /api/v1/dashboard/project/{project_id}`

Get project dashboard. Returns project dashboard with various chart data for mobile visualization.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Parameters:**

*   `project_id` (string, required): The project identifier.

**Responses:**

*   `200`: Project dashboard loaded successfully.
*   `403`: Access denied.
*   `404`: Project not found.

### Projects

#### `GET /api/v1/projects`

List user's projects.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Query Parameters:**

*   `page` (integer, optional, default: 1): Page number.
*   `per_page` (integer, optional, default: 25, max: 100): Items per page.
*   `status` (integer, optional): Filter by status.
*   `search` (string, optional): Search by project name.
*   `sort_by` (string, optional, default: name): Column to sort by.
*   `sort_direction` (string, optional, enum: [asc, desc], default: asc): Sort direction.

**Responses:**

*   `200`: Projects loaded successfully.
*   `401`: Unauthorized.

#### `GET /api/v1/projects/{id}`

Get project details.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Parameters:**

*   `id` (string, required): Project identifier or slug.

**Responses:**

*   `200`: Project loaded successfully.
*   `404`: Project not found.

#### `GET /api/v1/projects/{id}/custom_fields`

Get project custom fields. Returns all custom fields for the project, including mandatory and optional fields.

**Headers:**

*   `X-Redmine-API-Key` (string, required): The user's API token.

**Parameters:**

*   `id` (string, required): Project identifier or slug.

**Responses:**

*   `200`: Custom fields loaded successfully.
*   `404`: Project not found.

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request

## License

This plugin is open-source and available under the [MIT License](https://opensource.org/licenses/MIT).
