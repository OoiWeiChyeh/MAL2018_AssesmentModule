/*
***************************************************************************************************
* EXERCISE 7: TRIGGER IMPLEMENTATION
* Module: MAL2018 – Information Management & Retrieval
* Purpose: Automatically log trail additions for audit compliance
* Database: Azure SQL Edge (Docker)
***************************************************************************************************
*
* TRIGGER PURPOSE:
* - Automatically log when new trails are added to the database
* - Capture who added the trail, what trail was added, and when
* - Maintain immutable audit trail for compliance and accountability
* - No manual intervention required - fully automatic logging
*
* TRIGGER DESIGN:
* - Type: AFTER INSERT trigger (fires after successful insertion)
* - Table: CW1.TRAIL
* - Target: CW1.TRAIL_LOG (separate audit table)
* - Mechanism: Uses INSERTED pseudo-table to access new row data
*
* BENEFITS:
* - Automatic audit trail (no manual logging required)
* - Captures complete context (who, what, when)
* - Immutable log (denormalized for historical accuracy)
* - Supports compliance requirements
* - Transaction-safe (rolls back with parent transaction if error occurs)
*
***************************************************************************************************
*/

-- *************************************************************************************************
-- SECTION 1: DROP EXISTING TRIGGER
-- Purpose: Remove existing trigger to enable clean re-deployment
-- Reason: Allows trigger definition changes without conflicts
-- *************************************************************************************************
IF OBJECT_ID('CW1.trg_Trail_Insert_Log', 'TR') IS NOT NULL
    DROP TRIGGER CW1.trg_Trail_Insert_Log;
GO

-- *************************************************************************************************
-- SECTION 2: DROP AND CREATE TRAIL_LOG TABLE
-- Purpose: Create separate audit log table for storing trail addition history
-- Design: Denormalized for audit purposes (preserves historical data even if source changes)
-- *************************************************************************************************

-- Drop existing log table if exists
IF OBJECT_ID('CW1.TRAIL_LOG', 'U') IS NOT NULL
    DROP TABLE CW1.TRAIL_LOG;
GO

-- -------------------------------------------------------------------------------------------------
-- TABLE: TRAIL_LOG
-- Purpose: Audit log table for trail insertions
-- Normalization: Intentionally denormalized for audit purposes
-- Reason: Preserves historical data even if original USER or TRAIL records are modified/deleted
-- -------------------------------------------------------------------------------------------------
CREATE TABLE CW1.TRAIL_LOG (
    -- Primary key with auto-increment
    log_id INT IDENTITY(1,1),
    
    -- Trail information (captured at time of insertion)
    trail_id INT NOT NULL,
    trail_name NVARCHAR(255) NOT NULL,
    
    -- User information (captured at time of insertion)
    -- Denormalized: Stores user_id and email for complete audit trail
    added_by INT NOT NULL,
    added_by_email NVARCHAR(255) NOT NULL,
    
    -- Timestamp of log entry creation
    -- Default: GETDATE() automatically captures current date/time
    timestamp DATETIME NOT NULL DEFAULT GETDATE(),
    
    -- Constraints
    CONSTRAINT PK_TrailLog PRIMARY KEY (log_id)
);
GO

-- *************************************************************************************************
-- SECTION 3: TRIGGER CREATION
-- Purpose: Create AFTER INSERT trigger to automatically log trail additions
-- Trigger Type: AFTER INSERT (fires after INSERT operation completes successfully)
-- Mechanism: Accesses INSERTED pseudo-table containing newly inserted row(s)
-- Transaction: Operates within same transaction as parent INSERT
-- *************************************************************************************************
CREATE TRIGGER CW1.trg_Trail_Insert_Log
ON CW1.TRAIL
AFTER INSERT
AS
BEGIN
    -- Prevent extra result sets from interfering with INSERT operations
    SET NOCOUNT ON;
    
    -- -------------------------------------------------------------------------------------------------
    -- Trigger Logic
    -- Purpose: Insert audit log entry for each newly inserted trail
    -- 
    -- INSERTED Pseudo-Table:
    -- - System-generated table containing newly inserted row(s)
    -- - Available only within trigger context
    -- - Contains same structure as parent table (CW1.TRAIL)
    --
    -- Join Operation:
    -- - Joins INSERTED with USER table to retrieve email address
    -- - Email is denormalized in log for complete historical record
    --
    -- Denormalization Justification:
    -- - Preserves historical accuracy if user email changes
    -- - Ensures audit trail remains intact even if user is deleted
    -- - Complies with audit requirements for immutable records
    -- -------------------------------------------------------------------------------------------------
    INSERT INTO CW1.TRAIL_LOG (trail_id, trail_name, added_by, added_by_email)
    SELECT 
        i.trail_id,           -- Trail ID from newly inserted row
        i.trail_name,         -- Trail name from newly inserted row
        i.created_by,         -- User ID who created the trail
        u.email               -- User email retrieved via JOIN
    FROM 
        INSERTED i
        -- Join with USER table to get email address
        -- INNER JOIN is safe because foreign key constraint guarantees user exists
        INNER JOIN CW1.[USER] u ON i.created_by = u.user_id;
END;
GO

-- *************************************************************************************************
-- SECTION 4: TRIGGER TESTING
-- Purpose: Verify trigger fires correctly and logs data accurately
-- Steps: Check before state, insert trail, verify after state, validate correlation
-- *************************************************************************************************

-- -------------------------------------------------------------------------------------------------
-- Test Step 1: Before INSERT - Check initial log state
-- Purpose: Establish baseline for comparison
-- Expected: Empty table or previous log entries only
-- -------------------------------------------------------------------------------------------------
SELECT 
    log_id,
    trail_id,
    trail_name,
    added_by,
    added_by_email,
    timestamp
FROM CW1.TRAIL_LOG
ORDER BY log_id DESC;
GO

-- -------------------------------------------------------------------------------------------------
-- Test Step 2: Insert new trail to trigger the logging mechanism
-- Purpose: Test trigger fires on INSERT operation
-- Expected: Trigger automatically creates log entry
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
)
VALUES (
    'Trigger Test Trail',
    'Easy',
    'Trigger Test Location, Devon, England',
    3.5,
    50,
    'Loop',
    'Trail inserted to test trigger functionality.',
    4.00,
    1
);
GO

-- -------------------------------------------------------------------------------------------------
-- Test Step 3: After INSERT - Verify trigger created log entry
-- Purpose: Confirm trigger executed successfully
-- Expected: New log entry with matching trail information
-- -------------------------------------------------------------------------------------------------
SELECT 
    log_id,
    trail_id,
    trail_name,
    added_by,
    added_by_email,
    timestamp
FROM CW1.TRAIL_LOG
ORDER BY log_id DESC;
GO

-- -------------------------------------------------------------------------------------------------
-- Test Step 4: Verify trail exists in TRAIL table
-- Purpose: Confirm parent INSERT operation completed successfully
-- Expected: Trail record exists with matching data
-- -------------------------------------------------------------------------------------------------
SELECT 
    trail_id,
    trail_name,
    difficulty,
    location,
    created_by,
    created_date
FROM CW1.TRAIL
WHERE trail_name = 'Trigger Test Trail';
GO

-- -------------------------------------------------------------------------------------------------
-- Test Step 5: JOIN query to show correlation between TRAIL and TRAIL_LOG
-- Purpose: Demonstrate audit trail matches source data
-- Expected: Matching trail_id, trail_name, and user information
-- -------------------------------------------------------------------------------------------------
SELECT 
    t.trail_id,
    t.trail_name AS Trail_Table_Name,
    t.created_by AS Trail_Created_By,
    t.created_date AS Trail_Created_Date,
    tl.log_id,
    tl.trail_name AS Log_Trail_Name,
    tl.added_by AS Log_Added_By,
    tl.added_by_email AS Log_User_Email,
    tl.timestamp AS Log_Timestamp
FROM CW1.TRAIL t
INNER JOIN CW1.TRAIL_LOG tl ON t.trail_id = tl.trail_id
WHERE t.trail_name = 'Trigger Test Trail';
GO

-- -------------------------------------------------------------------------------------------------
-- Test Step 6: Test trigger with multiple inserts
-- Purpose: Verify trigger handles multiple simultaneous insertions
-- Expected: Multiple log entries created in one transaction
-- -------------------------------------------------------------------------------------------------
INSERT INTO CW1.TRAIL (trail_name, difficulty, location, length_km, route_type, created_by)
VALUES 
    ('Multi-Insert Test 1', 'Easy', 'Test Location 1', 2.0, 'Loop', 2),
    ('Multi-Insert Test 2', 'Moderate', 'Test Location 2', 4.0, 'Loop', 3);
GO

-- Verify multiple log entries created
SELECT 
    log_id,
    trail_id,
    trail_name,
    added_by,
    added_by_email,
    timestamp
FROM CW1.TRAIL_LOG
WHERE trail_name LIKE 'Multi-Insert Test%'
ORDER BY log_id DESC;
GO