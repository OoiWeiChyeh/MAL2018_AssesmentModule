/*
***************************************************************************************************
* EXERCISE 4: SQL TABLE CREATION AND DATA POPULATION
* Module: COMP2001 - Database Systems
* Purpose: Create normalized database tables for Trail Application
* Database: Azure SQL Edge (Docker)
* Server: dist-6-505.uopnet.plymouth.ac.uk
* Schema: CW1
***************************************************************************************************
* 
* TABLES SELECTED FOR IMPLEMENTATION:
* 1. USER - Stores user authentication and profile information
*    Justification: Essential for role-based access control and trail ownership tracking
*    Integration: Links with external Authenticator API
*
* 2. TRAIL - Stores comprehensive trail information
*    Justification: Core entity of application; contains all essential trail data for webpage display
*    Features: Difficulty levels, route types, ratings, location, and elevation data
*
* 3. TRAIL_FEATURE - Link entity resolving M:M relationship
*    Justification: Demonstrates proper normalization (3NF) by eliminating repeating groups
*    Benefit: Allows trails to have multiple features and features to be reused across trails
*
***************************************************************************************************
*/

-- *************************************************************************************************
-- SECTION 1: SCHEMA CREATION
-- Purpose: Create CW1 schema to organize coursework objects separately from other database objects
-- *************************************************************************************************
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'CW1')
BEGIN
    EXEC('CREATE SCHEMA CW1');
END
GO

-- *************************************************************************************************
-- SECTION 2: DROP EXISTING TABLES
-- Purpose: Remove existing tables to enable clean re-deployment
-- Order: Child tables first (TRAIL_FEATURE), then parent tables (TRAIL, USER)
-- Reason: Prevents foreign key constraint violations during drop operations
-- *************************************************************************************************
IF OBJECT_ID('CW1.TRAIL_FEATURE', 'U') IS NOT NULL
    DROP TABLE CW1.TRAIL_FEATURE;

IF OBJECT_ID('CW1.TRAIL', 'U') IS NOT NULL
    DROP TABLE CW1.TRAIL;

IF OBJECT_ID('CW1.USER', 'U') IS NOT NULL
    DROP TABLE CW1.[USER];
GO

-- *************************************************************************************************
-- SECTION 3: TABLE CREATION
-- Purpose: Create normalized tables following Third Normal Form (3NF)
-- Design: Eliminates repeating groups, partial dependencies, and transitive dependencies
-- *************************************************************************************************

-- -------------------------------------------------------------------------------------------------
-- TABLE 1: USER
-- Purpose: Store user information and roles for authentication and authorization
-- Normalization: 3NF - No repeating groups, no partial/transitive dependencies
-- Primary Key: user_id (surrogate key for optimal performance)
-- Integration: Email matches accounts in external Authenticator API
-- -------------------------------------------------------------------------------------------------
CREATE TABLE CW1.[USER] (
    -- Primary key column with auto-increment
    user_id INT IDENTITY(1,1),
    
    -- User identification and authentication fields
    -- Email is unique to prevent duplicate accounts
    email NVARCHAR(255) NOT NULL,
    
    -- Display name shown in user interface
    username NVARCHAR(100) NOT NULL,
    
    -- Optional full legal name
    full_name NVARCHAR(255) NULL,
    
    -- Role-based access control field
    -- Default role is 'user' for standard accounts
    role NVARCHAR(50) NOT NULL DEFAULT 'user',
    
    -- Audit field to track account creation
    registration_date DATETIME NOT NULL DEFAULT GETDATE(),
    
    -- Constraints definition
    CONSTRAINT PK_User PRIMARY KEY (user_id),
    CONSTRAINT UQ_User_Email UNIQUE (email),
    CONSTRAINT CK_User_Role CHECK (role IN ('admin', 'user'))
);
GO

-- -------------------------------------------------------------------------------------------------
-- TABLE 2: TRAIL
-- Purpose: Store comprehensive trail information
-- Normalization: 3NF - All non-key attributes depend only on primary key
-- Primary Key: trail_id (surrogate key)
-- Foreign Key: created_by references USER(user_id)
-- Business Rules: Length must be positive, rating must be between 1 and 5
-- -------------------------------------------------------------------------------------------------
CREATE TABLE CW1.TRAIL (
    -- Primary key column with auto-increment
    trail_id INT IDENTITY(1,1),
    
    -- Trail identification and basic information
    trail_name NVARCHAR(255) NOT NULL,
    
    -- Difficulty level constrained to three valid values
    difficulty NVARCHAR(50) NOT NULL,
    
    -- Human-readable location description
    location NVARCHAR(255) NOT NULL,
    
    -- Trail length in kilometers with two decimal precision
    length_km DECIMAL(10, 2) NOT NULL,
    
    -- Optional elevation gain in meters
    elevation_gain_m INT NULL,
    
    -- Route type constrained to three valid values
    route_type NVARCHAR(50) NOT NULL,
    
    -- Detailed trail description using MAX for unlimited text
    description_text NVARCHAR(MAX) NULL,
    
    -- Average rating with two decimal precision
    overall_rating DECIMAL(3, 2) NULL,
    
    -- Foreign key linking to user who created the trail
    created_by INT NOT NULL,
    
    -- Audit field to track trail creation
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    
    -- Constraints definition
    CONSTRAINT PK_Trail PRIMARY KEY (trail_id),
    
    -- Foreign key with referential integrity rules
    -- ON DELETE NO ACTION prevents deletion of users who have created trails
    -- ON UPDATE CASCADE ensures user_id updates propagate to trails
    CONSTRAINT FK_Trail_User FOREIGN KEY (created_by)
        REFERENCES CW1.[USER](user_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    
    -- Business rule constraints
    CONSTRAINT CK_Trail_Difficulty CHECK (difficulty IN ('Easy', 'Moderate', 'Hard')),
    CONSTRAINT CK_Trail_Length CHECK (length_km > 0),
    CONSTRAINT CK_Trail_Elevation CHECK (elevation_gain_m >= 0),
    CONSTRAINT CK_Trail_RouteType CHECK (route_type IN ('Loop', 'Out & back', 'Point to point')),
    CONSTRAINT CK_Trail_Rating CHECK (overall_rating >= 1.00 AND overall_rating <= 5.00)
);
GO

-- -------------------------------------------------------------------------------------------------
-- TABLE 3: TRAIL_FEATURE (Link Entity)
-- Purpose: Resolve many-to-many relationship between trails and features
-- Normalization: 3NF - Composite primary key, no transitive dependencies
-- Primary Key: Composite (trail_id, feature_name)
-- Foreign Key: trail_id references TRAIL(trail_id)
-- Cascade Rules: DELETE CASCADE automatically removes features when trail is deleted
-- -------------------------------------------------------------------------------------------------
CREATE TABLE CW1.TRAIL_FEATURE (
    -- Foreign key to TRAIL table, part of composite primary key
    trail_id INT NOT NULL,
    
    -- Feature name as part of composite primary key
    -- Examples: 'River', 'Waterfall', 'Historical Site'
    feature_name NVARCHAR(100) NOT NULL,
    
    -- Optional description providing details about the feature
    feature_description NVARCHAR(500) NULL,
    
    -- Constraints definition
    -- Composite primary key ensures unique trail-feature combinations
    CONSTRAINT PK_TrailFeature PRIMARY KEY (trail_id, feature_name),
    
    -- Foreign key with cascade rules
    -- ON DELETE CASCADE removes features when parent trail is deleted
    -- ON UPDATE CASCADE ensures trail_id updates propagate to features
    CONSTRAINT FK_TrailFeature_Trail FOREIGN KEY (trail_id)
        REFERENCES CW1.TRAIL(trail_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- *************************************************************************************************
-- SECTION 4: INDEX CREATION
-- Purpose: Optimize query performance for frequently accessed columns
-- Strategy: Create non-clustered indexes on foreign keys and commonly filtered columns
-- Performance: Improves JOIN operations and WHERE clause filtering
-- *************************************************************************************************

-- Index on USER.email for authentication lookups
-- Justification: Email is used frequently for user authentication queries
CREATE NONCLUSTERED INDEX IX_User_Email ON CW1.[USER](email);

-- Index on TRAIL.created_by for user's trail queries
-- Justification: Improves performance when filtering trails by creator
CREATE NONCLUSTERED INDEX IX_Trail_CreatedBy ON CW1.TRAIL(created_by);

-- Index on TRAIL.difficulty for filtering
-- Justification: Difficulty is commonly used in WHERE clauses for trail searches
CREATE NONCLUSTERED INDEX IX_Trail_Difficulty ON CW1.TRAIL(difficulty);

-- Index on TRAIL_FEATURE.trail_id for feature lookups
-- Justification: Improves JOIN performance when retrieving trail features
CREATE NONCLUSTERED INDEX IX_TrailFeature_TrailId ON CW1.TRAIL_FEATURE(trail_id);
GO

-- *************************************************************************************************
-- SECTION 5: DEMO DATA INSERTION
-- Purpose: Insert test data for verification and testing
-- Data Source: User accounts match Authenticator API requirements
-- Coverage: Sufficient data to demonstrate all relationships and constraints
-- *************************************************************************************************

-- -------------------------------------------------------------------------------------------------
-- Insert users matching Authenticator API accounts
-- These accounts are required for authentication integration
-- Passwords are stored in the external Authenticator API, not in this database
-- -------------------------------------------------------------------------------------------------
INSERT INTO CW1.[USER] (email, username, full_name, role) VALUES
    ('grace@plymouth.ac.uk', 'GraceH', 'Grace Hopper', 'user'),
    ('tim@plymouth.ac.uk', 'TimBL', 'Tim Berners-Lee', 'admin'),
    ('ada@plymouth.ac.uk', 'AdaL', 'Ada Lovelace', 'user');
GO

-- -------------------------------------------------------------------------------------------------
-- Insert sample trails with realistic data
-- Data represents actual Devon, England locations
-- Variety: Different difficulties, route types, and ratings for comprehensive testing
-- -------------------------------------------------------------------------------------------------
INSERT INTO CW1.TRAIL (
    trail_name, 
    difficulty, 
    location, 
    length_km, 
    elevation_gain_m, 
    route_type, 
    description_text, 
    overall_rating, 
    created_by
) VALUES
    (
        'Plymbridge Circular',
        'Easy',
        'Plymbridge, Plymouth, Devon, England',
        5.2,
        120,
        'Loop',
        'A scenic woodland trail following the River Plym with historical railway remnants.',
        4.50,
        1
    ),
    (
        'Dartmoor Summit Trail',
        'Hard',
        'Princetown, Dartmoor, Devon, England',
        12.8,
        450,
        'Loop',
        'Challenging moorland hike with stunning views across Dartmoor National Park.',
        4.80,
        2
    ),
    (
        'South West Coast Path Section',
        'Moderate',
        'Plymouth Hoe to Wembury, Devon, England',
        8.5,
        200,
        'Point to point',
        'Coastal path with breathtaking sea views and clifftop walking.',
        4.70,
        3
    ),
    (
        'Burrator Reservoir Walk',
        'Easy',
        'Burrator, Dartmoor, Devon, England',
        6.0,
        80,
        'Loop',
        'Family-friendly reservoir walk through pine forests with picnic areas.',
        4.30,
        1
    ),
    (
        'Buckland Beacon Ascent',
        'Moderate',
        'Buckland-in-the-Moor, Devon, England',
        4.5,
        180,
        'Out & back',
        'Short but steep climb to historic beacon with panoramic views.',
        4.60,
        2
    );
GO

-- -------------------------------------------------------------------------------------------------
-- Insert trail features demonstrating many-to-many relationship
-- Design: Multiple features per trail, features can be reused across trails
-- Coverage: Demonstrates link entity functionality with realistic feature data
-- -------------------------------------------------------------------------------------------------
INSERT INTO CW1.TRAIL_FEATURE (trail_id, feature_name, feature_description) VALUES
    (1, 'River', 'River Plym runs alongside the trail'),
    (1, 'Historical Site', 'Old railway viaduct and tramway remains'),
    (1, 'Forest', 'Ancient woodland with diverse flora'),
    (2, 'Mountain Views', 'Panoramic views of Dartmoor tors'),
    (2, 'Wildlife', 'Wild ponies and rare birds'),
    (3, 'Ocean Views', 'Spectacular coastal cliff scenery'),
    (3, 'Beach Access', 'Multiple beaches along the route'),
    (4, 'Lake', 'Burrator Reservoir with calm waters'),
    (4, 'Picnic Area', 'Multiple spots for family picnics'),
    (5, 'Historical Site', 'Ancient beacon dating to medieval times'),
    (5, 'Summit', 'Elevated viewpoint at 400m');
GO

-- *************************************************************************************************
-- SECTION 6: VERIFICATION QUERIES
-- Purpose: Generate SELECT statements to verify successful implementation
-- Usage: Run these queries and capture screenshots for report documentation
-- Coverage: All tables with all columns to demonstrate data presence
-- *************************************************************************************************

-- Verify USER table data
-- Purpose: Demonstrate all user accounts are inserted correctly
SELECT 
    user_id,
    email,
    username,
    full_name,
    role,
    registration_date
FROM CW1.[USER]
ORDER BY user_id;
GO

-- Verify TRAIL table data
-- Purpose: Demonstrate all trails are inserted with correct attributes and relationships
SELECT 
    trail_id,
    trail_name,
    difficulty,
    location,
    length_km,
    elevation_gain_m,
    route_type,
    overall_rating,
    created_by,
    created_date
FROM CW1.TRAIL
ORDER BY trail_id;
GO

-- Verify TRAIL_FEATURE link entity data
-- Purpose: Demonstrate many-to-many relationship implementation
-- Join: Includes trail name for better readability in screenshot
SELECT 
    tf.trail_id,
    t.trail_name,
    tf.feature_name,
    tf.feature_description
FROM CW1.TRAIL_FEATURE tf
INNER JOIN CW1.TRAIL t ON tf.trail_id = t.trail_id
ORDER BY tf.trail_id, tf.feature_name;
GO