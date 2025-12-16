# CW2 TrailService REST API

## Overview

A RESTful API microservice for managing hiking trail information, implementing the database schema from CW1. This service provides complete CRUD operations for trail management, read-only user access, and trail feature association through a standardized HTTP interface.

**Author**: BSCS2509254  
**Module**: MAL2018 - Information Management & Retrieval  
**Institution**: University of Plymouth  
**Date**: December 2025

## Architecture

The system follows a three-tier architecture implementing the microservices pattern with database-per-service isolation:

**Database Layer**: Microsoft SQL Server (Azure SQL Edge) containing the CW1 schema with USER, TRAIL, TRAIL_FEATURE, and TRAIL_LOG tables. The schema is fully normalized to Third Normal Form (3NF) with appropriate foreign key constraints and cascade behaviors.

**ORM Layer**: SQLAlchemy provides object-relational mapping between Python classes and database tables. Model definitions mirror the database schema while relationship declarations enable automatic JOIN operations and referential integrity maintenance.

**API Layer**: Connexion framework builds on Flask to provide specification-first API development. The swagger.yml OpenAPI 3.0 specification defines all endpoints, validation rules, and documentation, with automatic request/response validation against defined schemas.

## Technical Stack

- **Framework**: Connexion 2.14.1 (Flask-based)
- **ORM**: SQLAlchemy 2.0.22
- **Serialization**: Marshmallow 3.20.1 with marshmallow-sqlalchemy 0.29.0
- **Database**: Microsoft SQL Server / Azure SQL Edge
- **Database Driver**: pyodbc 5.1.0 (ODBC Driver 18 for SQL Server)
- **API Documentation**: Swagger UI (bundled with Connexion)
- **Python Version**: 3.8+

## Database Schema

The implementation uses the CW1 schema under the `CW1` namespace in the `COMP2001_Test` database:

**USER Table**: Stores registered users with authentication details, roles, and registration timestamps. Each user can create multiple trails (one-to-many relationship).

**TRAIL Table**: Contains trail metadata including name, difficulty, location, length, elevation gain, route type, description, rating, and creation information. Each trail is linked to exactly one creator via foreign key to USER.

**TRAIL_FEATURE Table**: Junction table implementing many-to-many relationships between trails and features. Uses composite primary key (trail_id, feature_name) with CASCADE DELETE on trail removal.

**TRAIL_LOG Table**: Audit table populated by database trigger, recording trail creation events with timestamp and creator information.

**vw_TrailsWithCreator View**: Pre-joined view combining trail and user data with calculated fields including days_since_created.

## Project Structure

```
.
├── app.py                  # Application entry point and server initialization
├── config.py               # Configuration: database connection, SQLAlchemy, Marshmallow
├── models.py               # ORM models and Marshmallow schemas
├── swagger.yml             # OpenAPI 3.0 specification
├── trails.py               # Trail CRUD endpoint controllers
├── users.py                # User read-only endpoint controllers
├── features.py             # Trail feature relationship controllers
├── views.py                # Database view access controllers
├── requirements.txt        # Python package dependencies
└── README.md              # Project documentation
```

## Installation

### Prerequisites

1. Python 3.8 or higher
2. Microsoft SQL Server or Azure SQL Edge
3. ODBC Driver 18 for SQL Server
4. Docker (if using Azure SQL Edge container)

### Database Setup

Start Azure SQL Edge using Docker:

```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 --name azuresqledge \
  -d mcr.microsoft.com/azure-sql-edge
```

Execute the CW1 schema creation scripts to establish tables, constraints, stored procedures, triggers, and views. Populate with sample data using the test data SQL scripts provided in the appendix.

### Python Environment

Create and activate a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

### Configuration

Update database connection settings in `config.py` if using non-default credentials:

```python
connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=COMP2001_Test;"
    "UID=SA;"
    "PWD=YourStrong!Passw0rd;"
    "TrustServerCertificate=yes;"
)
```

## Running the Application

Start the development server:

```bash
python app.py
```

The server will start on port 5000 with the following access points:

- **API Base**: http://localhost:5000/api
- **Swagger UI**: http://localhost:5000/api/ui
- **Root Redirect**: http://localhost:5000 (redirects to Swagger UI)
- **Health Check**: http://localhost:5000/health

Debug mode is enabled by default for development. Disable for production deployment.

## API Endpoints

### Trail Management

**GET /api/trails**: Retrieve all trails with nested creator and feature information. Returns array ordered by creation date (descending).

**POST /api/trails**: Create new trail. Requires trail_name, difficulty, location, length_km, route_type, and creator email. Returns 201 Created with generated trail_id.

**GET /api/trails/{trail_id}**: Retrieve specific trail by ID. Returns complete trail object with nested relationships or 404 if not found.

**PATCH /api/trails/{trail_id}**: Partial update of existing trail. Accepts any subset of trail fields. Validates creator email if provided.

**DELETE /api/trails/{trail_id}**: Permanently delete trail and cascade remove associated features. Returns 200 OK with confirmation message.

### Trail Features

**GET /api/trails/{trail_id}/features**: Retrieve all features associated with specified trail. Returns array of feature objects or 404 if trail has no features.

### Database Views

**GET /api/trails/view**: Retrieve all trails from vw_TrailsWithCreator with flattened creator information and calculated fields.

**GET /api/trails/view/{trail_id}**: Retrieve single trail from database view with pre-joined user data.

### User Management

**GET /api/users**: Retrieve all registered users. User creation/modification handled by external authentication service (read-only access).

**GET /api/users/{user_id}**: Retrieve specific user by ID with nested list of created trails.

## Request/Response Examples

### Create Trail

Request:
```bash
curl -X POST http://localhost:5000/api/trails \
  -H "Content-Type: application/json" \
  -d '{
    "trail_name": "Dartmoor Ridge Walk",
    "difficulty": "Hard",
    "location": "Dartmoor, Devon, England",
    "length_km": 15.8,
    "elevation_gain_m": 620,
    "route_type": "Out & back",
    "description_text": "Challenging ridge walk with spectacular moorland views",
    "overall_rating": 4.9,
    "email": "ada@plymouth.ac.uk"
  }'
```

Response (201 Created):
```json
{
  "trail_id": 4,
  "trail_name": "Dartmoor Ridge Walk",
  "difficulty": "Hard",
  "location": "Dartmoor, Devon, England",
  "length_km": 15.8,
  "elevation_gain_m": 620,
  "route_type": "Out & back",
  "description_text": "Challenging ridge walk with spectacular moorland views",
  "overall_rating": 4.9,
  "created_date": "2025-12-16T14:30:00",
  "created_by": 2,
  "creator": {
    "user_id": 2,
    "username": "ada456",
    "email": "ada@plymouth.ac.uk"
  },
  "features": []
}
```

### Update Trail

Request:
```bash
curl -X PATCH http://localhost:5000/api/trails/4 \
  -H "Content-Type: application/json" \
  -d '{
    "overall_rating": 5.0,
    "description_text": "Outstanding ridge walk with panoramic moorland views"
  }'
```

Response (200 OK): Returns updated trail object with modified fields.

### Retrieve Trail Features

Request:
```bash
curl http://localhost:5000/api/trails/1/features
```

Response (200 OK):
```json
[
  {
    "feature_name": "River",
    "feature_description": "River Plym runs alongside the trail"
  },
  {
    "feature_name": "Forest",
    "feature_description": "Woodland area with diverse wildlife"
  },
  {
    "feature_name": "Dog-friendly",
    "feature_description": "Trail suitable for dogs on leash"
  }
]
```

## Validation and Constraints

The API enforces validation at multiple levels for defense in depth:

**OpenAPI Schema Validation**: Connexion validates request data against swagger.yml before reaching controller code. This includes type checking, enum validation, and required field verification.

**Database Constraints**: CHECK constraints enforce difficulty values (Easy, Moderate, Hard) and route_type values (Loop, Out & back, Point to point). Foreign key constraints maintain referential integrity.

**Business Logic Validation**: Controller code verifies user existence before trail creation, validates email format, and ensures trails link to valid creators.

**Numeric Boundaries**: length_km must be positive (minimum 0.1), overall_rating must be between 1.0 and 5.0, elevation_gain_m must be non-negative.

## Error Handling

The API returns RFC 7807 Problem Details format for all errors:

**400 Bad Request**: Schema validation failure, invalid enum values, or constraint violations.

**404 Not Found**: Requested resource does not exist (trail ID, user ID, or email not found).

**500 Internal Server Error**: Database connection failures or unexpected exceptions.

Error response structure:
```json
{
  "detail": "User with email nonexistent@example.com does not exist",
  "status": 404,
  "title": "Not Found",
  "type": "about:blank"
}
```

## Testing

Comprehensive test suite covering 18 test cases as documented in the coursework specification:

- Positive cases: Successful CRUD operations across all endpoints
- Negative cases: Non-existent resources, invalid identifiers
- Validation cases: Enum constraint violations, boundary conditions
- Relationship cases: Cascade deletions, junction table operations
- View access cases: Database view query validation

Execute tests using cURL commands from the test specification or interactively through Swagger UI. All endpoints validated against expected HTTP status codes and response formats.

## Known Limitations

**Authentication and Authorization**: No access control implemented. Production deployment requires integration with external authentication service and role-based authorization.

**Rate Limiting**: No request throttling. Vulnerable to denial of service without middleware or reverse proxy rate limiting.

**Pagination**: List endpoints return complete datasets. Large result sets will impact performance and should implement offset/limit pagination.

**Audit Logging**: Only trail creation logged via trigger. Updates and deletions not captured in TRAIL_LOG table.

**HTTPS**: TrustServerCertificate bypasses SSL validation. Production requires proper certificate configuration.

**Transaction Isolation**: Default isolation level used. High-concurrency scenarios may require explicit transaction management.

## Security Considerations

**SQL Injection Prevention**: All queries use parameterized statements through SQLAlchemy ORM or named parameter binding for raw SQL.

**Input Validation**: Multi-layer validation through OpenAPI schema, Python type hints, and database constraints prevents malformed data.

**Credential Management**: Database credentials hardcoded in config.py for development. Production must use environment variables or secure credential stores.

**CORS Configuration**: Not implemented. Cross-origin requests will fail without appropriate headers.

**Sensitive Data Exposure**: User emails included in API responses. Consider privacy implications and implement field-level access control.

## Future Enhancements

**Authentication Integration**: OAuth 2.0 or OpenID Connect for user authentication with JWT token validation and role-based access control.

**Pagination and Filtering**: Implement cursor-based pagination for list endpoints with query parameters for filtering (difficulty, location, rating range) and sorting.

**Comprehensive Audit Logging**: Expand TRAIL_LOG to capture all modifications with before/after values using temporal table pattern or event sourcing.

**API Versioning**: Implement URL-based versioning (/v1/trails) or header-based versioning to support backward compatibility during API evolution.

**Monitoring and Observability**: Integrate Prometheus metrics, structured logging, and distributed tracing for operational visibility.

**Caching Layer**: Implement Redis or Memcached for frequently accessed data to reduce database load and improve response times.

**Stored Procedure Integration**: Expose CW1 stored procedures (sp_InsertTrail, sp_UpdateTrail, sp_DeleteTrail) as alternative endpoints for complex operations.

## Development Notes

The codebase includes extensive inline documentation following PEP 257 docstring conventions. Each controller function documents purpose, parameters, return values, error conditions, and relevant design decisions.

Database migrations are manual through SQL scripts. Production systems should implement automated migration tools like Alembic for version control and rollback capability.

The swagger.yml specification serves as the single source of truth for API contracts. Changes to endpoints require updates to both specification and implementation to maintain synchronization.

## License

Academic coursework for MAL2018 module. Not licensed for commercial use.

## Contact

For questions regarding this implementation:
- Student ID: BSCS2509254
- Email: BSCS2509254@plymouth.ac.uk
- Module: MAL2018 - Information Management & Retrieval
