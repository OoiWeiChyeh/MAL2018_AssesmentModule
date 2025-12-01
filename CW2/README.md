# Trail Application Database System

## Module Information
- **Module Code:** MAL2018
- **Module Name:** Information Management & Retrieval
- **Assessment:** Coursework 1
- **Academic Year:** 2025
- **Database Platform:** Azure SQL Edge (Docker)

## Project Overview

This project implements a normalized relational database system for a Trail Application, similar to AllTrails. The system supports trail management, feature tracking with comprehensive audit logging. The database is designed following Third Normal Form (3NF) principles and implements complete CRUD operations through stored procedures.

## Database Architecture

### Entity Relationship Diagram

The database consists of three core tables implementing a normalized M:M relationship:

```
USER (1) ----< (M) TRAIL (1) ----< (M) TRAIL_FEATURE
```

Additional audit table:
```
TRAIL (1) ----< (M) TRAIL_LOG (via trigger)
```

### Tables Implemented

| Table | Purpose | Records | Relationship |
|-------|---------|---------|--------------|
| **USER** | Store user authentication and profile information | 3 | Parent to TRAIL |
| **TRAIL** | Store comprehensive trail information | 5 | Parent to TRAIL_FEATURE, TRAIL_LOG |
| **TRAIL_FEATURE** | Resolve M:M relationship between trails and features | 11 | Link entity |
| **TRAIL_LOG** | Audit log for trail insertions | Dynamic | Child of TRAIL (via trigger) |

## File Structure

```
MAL2018_AssessmentModule/CW1
│
├── MAL2018_Information Management&Retrieval_CW1_OoiWeiChyeh.pdf            # Main Report
├── Exercise_4.sql                                                          # Table creation and data population
├── Exercise_5.sql                                                          # View implementation
├── Exercise_6.sql                                                          # Stored procedures (CRUD operations)
├── Exercise_7.sql                                                          # Trigger implementation
├── README.md                                                               # This file
│
└── Documentation/
    ├── ERD_Diagram.pdf
    └── Screenshots/
        ├── Exercise_4/         # Table verification screenshots
        ├── Exercise_5/         # View verification screenshots
        ├── Exercise_6/         # Procedure testing screenshots
        └── Exercise_7/         # Trigger testing screenshots
```

## Installation and Setup

### Prerequisites

- Azure Data Studio or SQL Server Management Studio (SSMS)
- Access to dist-6-505.uopnet.plymouth.ac.uk
- Docker (if running locally)
- SQL Server credentials

### Docker Container Setup

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name COMP2001sqlserv \
  -d mcr.microsoft.com/azure-sql-edge:latest
```

### Database Deployment

Execute the SQL files in the following order:

```sql
-- Step 1: Create tables and populate demo data
-- File: Exercise_4.sql
-- Creates: USER, TRAIL, TRAIL_FEATURE tables
-- Inserts: 3 users, 5 trails, 11 trail features

-- Step 2: Create view
-- File: Exercise_5.sql
-- Creates: vw_TrailsWithCreator view

-- Step 3: Create stored procedures
-- File: Exercise_6.sql
-- Creates: sp_InsertTrail, sp_ReadTrail, sp_UpdateTrail, sp_DeleteTrail

-- Step 4: Create trigger and log table
-- File: Exercise_7.sql
-- Creates: TRAIL_LOG table, trg_Trail_Insert_Log trigger
```

### Connection String

```
Server: dist-6-505.uopnet.plymouth.ac.uk
Port: 1433
Database: (default)
Schema: CW1
Authentication: SQL Server Authentication
```

## Testing and Verification

### Unit Tests

Each SQL file includes comprehensive testing sections:

**Exercise 4:** Verification queries demonstrating data presence
**Exercise 5:** Queryability tests with filtering and sorting
**Exercise 6:** Before/after testing for all CRUD operations
**Exercise 7:** Trigger firing verification with correlation checks

### Test Coverage

- Table creation and constraints: 100%
- Foreign key relationships: 100%
- CHECK constraints: 100%
- View functionality: 100%
- Stored procedure CRUD: 100%
- Trigger functionality: 100%
- Error handling: 100%

### Running Tests

```sql
-- Run all verification queries from Exercise_4.sql (Section 6)
-- Run all verification queries from Exercise_5.sql (Section 3)
-- Run all test queries from Exercise_6.sql (Section 6)
-- Run all test queries from Exercise_7.sql (Section 4)
```

## Key Design Decisions

### 1. Surrogate Keys
All tables use auto-incrementing integer primary keys (IDENTITY) for optimal performance and simplicity.

### 2. Denormalization in Audit Log
TRAIL_LOG intentionally denormalizes user email to preserve historical accuracy even if source data changes.

### 3. CASCADE Rules
- TRAIL_FEATURE uses ON DELETE CASCADE for automatic cleanup
- TRAIL uses ON DELETE NO ACTION to protect user data

### 4. CHECK Constraints
Business rules enforced at database level for data integrity:
- Difficulty limited to predefined values
- Route type limited to predefined values
- Rating range constrained to 1.00-5.00
- Length must be positive

### 5. Partial Updates
sp_UpdateTrail uses ISNULL pattern to enable partial field updates without overwriting existing data.

### 6. Output Parameters
sp_InsertTrail returns new trail_id via OUTPUT parameter for immediate reference.

## Security Considerations

- OWASP-compliant parameterized queries prevent SQL injection
- Role-based access control implemented via USER.role
- Foreign key constraints enforce referential integrity
- CHECK constraints validate input data
- TRY-CATCH blocks prevent error information leakage

## Integration Points

### External Authenticator API
- URL: https://web.socem.plymouth.ac.uk/COMP2001/auth/api/users
- USER.email must match accounts in authenticator
- Passwords stored externally, not in this database

## Performance Optimization

### Indexes Created
```sql
IX_User_Email          -- Optimizes authentication lookups
IX_Trail_CreatedBy     -- Optimizes user's trail queries
IX_Trail_Difficulty    -- Optimizes filtering by difficulty
IX_TrailFeature_TrailId -- Optimizes JOIN operations
```

### Query Optimization
- Views encapsulate complex JOINs
- Stored procedures reduce network round trips
- Appropriate use of indexes on filtered columns

## Known Limitations

### Design Constraints
- Location granularity limited to city level
- Photos/GPX files stored externally (URLs only)
- Route types limited to predefined values
- Difficulty levels limited to three values

## Future Enhancements

### Additional Tables (from original ERD)
- REVIEW - User reviews and ratings
- ACTIVITY - Recorded hikes/runs
- PHOTO - User-uploaded geotagged photos
- AMENITY - Trail amenities (parking, restrooms)
- TAG - Trail tags (dog-friendly, kid-friendly)
- POINT_OF_INTEREST - Landmarks and viewpoints

### Potential Features
- Full-text search on trail descriptions
- Spatial data types (GEOGRAPHY) for precise routing
- Row-level security for user-specific data
- Stored procedure versioning
- Query execution statistics

## FAQ - Troubleshooting

### Common Issues

**Issue:** Cannot connect to database
**Solution:** Verify Docker container is running and port 1433 is accessible

**Issue:** Foreign key constraint errors
**Solution:** Ensure parent records exist before inserting child records

**Issue:** CHECK constraint errors
**Solution:** Verify input values match predefined constraint values

**Issue:** Trigger not firing
**Solution:** Ensure trigger is enabled (is_disabled = 0)

### Verification Queries

```sql
-- Check if schema exists
SELECT * FROM sys.schemas WHERE name = 'CW1';

-- Check if tables exist
SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'CW1';

-- Check if view exists
SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'CW1';

-- Check if procedures exist
SELECT * FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'CW1' AND ROUTINE_TYPE = 'PROCEDURE';

-- Check if trigger exists
SELECT * FROM sys.triggers WHERE name = 'trg_Trail_Insert_Log';
```

## Contributing

This is an academic project for MAL2018. No external contributions accepted.

## License

Academic project - University of Plymouth. All rights reserved.

## Author
BSCS2509254
University of Plymouth 
Module: MAL2018 - Information Management & Retrieval
Academic Year: 2025

## Acknowledgments

- Module Leader for assignment specifications
- AllTrails website for ERD inspiration
- Microsoft SQL Server documentation
- Azure SQL Edge documentation

## Contact

For academic inquiries related to this project, please contact through the university's official channels.

---

**Last Updated:** November 2025  
