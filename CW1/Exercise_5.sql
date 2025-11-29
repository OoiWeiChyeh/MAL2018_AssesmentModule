/*
***************************************************************************************************
* EXERCISE 5: VIEW IMPLEMENTATION
* Module: MAL2018 – Information Management & Retrieval
* Purpose: Create queryable view combining TRAIL and USER tables for trails webpage
* Database: Azure SQL Edge (Docker)
***************************************************************************************************
*
* VIEW PURPOSE:
* - Combine trail information with creator details
* - Substantially form the trails webpage display
* - Simplify frontend queries by encapsulating JOIN logic
* - Provide single point of access for trail and creator data
*
* BENEFITS:
* - Simplifies application queries (single SELECT instead of JOIN)
* - Encapsulates business logic in database layer
* - Improves security by hiding underlying table structure
* - Enables easy filtering and sorting without complex JOIN syntax
* - Calculates derived fields (trail age) automatically
*
***************************************************************************************************
*/

-- *************************************************************************************************
-- SECTION 1: DROP EXISTING VIEW
-- Purpose: Remove existing view to enable clean re-deployment
-- Reason: Allows view definition changes without conflicts
-- *************************************************************************************************
IF OBJECT_ID('CW1.vw_TrailsWithCreator', 'V') IS NOT NULL
    DROP VIEW CW1.vw_TrailsWithCreator;
GO

-- *************************************************************************************************
-- SECTION 2: VIEW CREATION
-- Purpose: Create view combining TRAIL and USER tables with calculated fields
-- Tables Combined: CW1.TRAIL (trail information) and CW1.USER (creator information)
-- Join Type: INNER JOIN (only shows trails with valid creators)
-- Calculated Field: days_since_created shows trail age in days
-- *************************************************************************************************
CREATE VIEW CW1.vw_TrailsWithCreator
AS
SELECT 
    -- -------------------------------------------------------------------------------------------------
    -- Trail Information Columns
    -- Purpose: All essential trail attributes needed for webpage display
    -- -------------------------------------------------------------------------------------------------
    t.trail_id,
    t.trail_name,
    t.difficulty,
    t.location,
    t.length_km,
    t.elevation_gain_m,
    t.route_type,
    t.description_text,
    t.overall_rating,
    t.created_date,
    
    -- -------------------------------------------------------------------------------------------------
    -- Creator Information Columns
    -- Purpose: User details for attribution and access control
    -- Aliased: Prefixed with 'creator_' for clarity in application code
    -- -------------------------------------------------------------------------------------------------
    u.user_id AS creator_id,
    u.username AS creator_username,
    u.email AS creator_email,
    u.role AS creator_role,
    
    -- -------------------------------------------------------------------------------------------------
    -- Calculated Fields
    -- Purpose: Derive trail age for display and sorting
    -- Calculation: DATEDIFF returns number of days between creation and current date
    -- -------------------------------------------------------------------------------------------------
    DATEDIFF(DAY, t.created_date, GETDATE()) AS days_since_created
    
FROM 
    CW1.TRAIL t
    -- INNER JOIN ensures only trails with valid creators are returned
    -- Foreign key relationship guarantees referential integrity
    INNER JOIN CW1.[USER] u ON t.created_by = u.user_id;
GO

-- *************************************************************************************************
-- SECTION 3: VIEW VERIFICATION QUERIES
-- Purpose: Demonstrate view functionality and queryability
-- Coverage: Basic query, filtering, sorting, and calculated field usage
-- *************************************************************************************************

-- -------------------------------------------------------------------------------------------------
-- Query 1: Basic view query
-- Purpose: Retrieve all trails with creator information
-- Usage: Primary query for trails webpage display
-- -------------------------------------------------------------------------------------------------
SELECT 
    trail_id,
    trail_name,
    difficulty,
    location,
    length_km,
    route_type,
    overall_rating,
    creator_username,
    creator_email,
    days_since_created
FROM CW1.vw_TrailsWithCreator
ORDER BY created_date DESC;
GO

-- -------------------------------------------------------------------------------------------------
-- Query 2: Filtered view query
-- Purpose: Demonstrate view is queryable with WHERE clause
-- Use Case: Filter trails by difficulty level
-- -------------------------------------------------------------------------------------------------
SELECT 
    trail_name,
    difficulty,
    location,
    length_km,
    creator_username,
    overall_rating
FROM CW1.vw_TrailsWithCreator
WHERE difficulty = 'Easy'
ORDER BY overall_rating DESC;
GO

-- -------------------------------------------------------------------------------------------------
-- Query 3: Filtered by creator
-- Purpose: Show all trails created by specific user
-- Use Case: User profile page showing their created trails
-- -------------------------------------------------------------------------------------------------
SELECT 
    trail_name,
    difficulty,
    location,
    overall_rating,
    days_since_created
FROM CW1.vw_TrailsWithCreator
WHERE creator_username = 'TimBL'
ORDER BY created_date DESC;
GO

-- -------------------------------------------------------------------------------------------------
-- Query 4: Filtered by rating
-- Purpose: Show highly-rated trails only
-- Use Case: Featured trails section on homepage
-- -------------------------------------------------------------------------------------------------
SELECT 
    trail_name,
    difficulty,
    location,
    overall_rating,
    creator_username
FROM CW1.vw_TrailsWithCreator
WHERE overall_rating >= 4.5
ORDER BY overall_rating DESC;
GO