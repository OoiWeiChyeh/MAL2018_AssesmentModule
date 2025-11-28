/*
***************************************************************************************************
* EXERCISE 6: STORED PROCEDURES - CRUD OPERATIONS
* Module: COMP2001 - Database Systems
* Purpose: Implement complete CRUD functionality for TRAIL table
* Database: Azure SQL Edge (Docker)
* Server: dist-6-505.uopnet.plymouth.ac.uk
* Schema: CW1
***************************************************************************************************
*
* STORED PROCEDURES IMPLEMENTED:
* 1. sp_InsertTrail - CREATE operation
* 2. sp_ReadTrail - READ operation
* 3. sp_UpdateTrail - UPDATE operation
* 4. sp_DeleteTrail - DELETE operation
*
* DESIGN PRINCIPLES:
* - Comprehensive error handling using TRY-CATCH blocks
* - Input validation before data modification
* - Informative messages for debugging and logging
* - OWASP-compliant parameterization to prevent SQL injection
* - Transaction-safe operations
*
***************************************************************************************************
*/

-- *************************************************************************************************
-- SECTION 1: DROP EXISTING PROCEDURES
-- Purpose: Remove existing procedures to enable clean re-deployment
-- Order: Drop all CRUD procedures
-- *************************************************************************************************
IF OBJECT_ID('CW1.sp_InsertTrail', 'P') IS NOT NULL
    DROP PROCEDURE CW1.sp_InsertTrail;
IF OBJECT_ID('CW1.sp_ReadTrail', 'P') IS NOT NULL
    DROP PROCEDURE CW1.sp_ReadTrail;
IF OBJECT_ID('CW1.sp_UpdateTrail', 'P') IS NOT NULL
    DROP PROCEDURE CW1.sp_UpdateTrail;
IF OBJECT_ID('CW1.sp_DeleteTrail', 'P') IS NOT NULL
    DROP PROCEDURE CW1.sp_DeleteTrail;
GO

-- *************************************************************************************************
-- SECTION 2: CREATE PROCEDURE - sp_InsertTrail
-- Purpose: Insert new trail with validation and error handling
-- Parameters: All trail attributes except auto-generated fields
-- Returns: New trail_id via OUTPUT parameter
-- Error Handling: Validates creator exists, checks constraint values
-- *************************************************************************************************
CREATE PROCEDURE CW1.sp_InsertTrail
    -- Required parameters
    @trail_name NVARCHAR(255),
    @difficulty NVARCHAR(50),
    @location NVARCHAR(255),
    @length_km DECIMAL(10, 2),
    @route_type NVARCHAR(50),
    @created_by INT,
    
    -- Optional parameters with NULL defaults
    @elevation_gain_m INT = NULL,
    @description_text NVARCHAR(MAX) = NULL,
    @overall_rating DECIMAL(3, 2) = NULL,
    
    -- Output parameter to return new trail_id to caller
    @new_trail_id INT OUTPUT
AS
BEGIN
    -- Prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- -------------------------------------------------------------------------------------------------
        -- Validation 1: Verify creator exists in USER table
        -- Purpose: Ensure referential integrity before insert
        -- Error: Raise error if user_id does not exist
        -- -------------------------------------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM CW1.[USER] WHERE user_id = @created_by)
        BEGIN
            RAISERROR('Error: Creator user_id does not exist in USER table', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 2: Check difficulty value
        -- Purpose: Ensure difficulty matches CHECK constraint values
        -- Error: Raise error if invalid difficulty provided
        -- -------------------------------------------------------------------------------------------------
        IF @difficulty NOT IN ('Easy', 'Moderate', 'Hard')
        BEGIN
            RAISERROR('Error: Difficulty must be Easy, Moderate, or Hard', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 3: Check route type value
        -- Purpose: Ensure route_type matches CHECK constraint values
        -- Error: Raise error if invalid route type provided
        -- -------------------------------------------------------------------------------------------------
        IF @route_type NOT IN ('Loop', 'Out & back', 'Point to point')
        BEGIN
            RAISERROR('Error: Route type must be Loop, Out & back, or Point to point', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 4: Check optional rating value if provided
        -- Purpose: Ensure rating is within valid range if not NULL
        -- Error: Raise error if rating outside 1.00 to 5.00 range
        -- -------------------------------------------------------------------------------------------------
        IF @overall_rating IS NOT NULL AND (@overall_rating < 1.00 OR @overall_rating > 5.00)
        BEGIN
            RAISERROR('Error: Overall rating must be between 1.00 and 5.00', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Insert Operation
        -- Purpose: Add new trail to database
        -- SCOPE_IDENTITY: Returns the last identity value inserted in the same scope
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
            @trail_name, 
            @difficulty, 
            @location, 
            @length_km, 
            @elevation_gain_m, 
            @route_type, 
            @description_text, 
            @overall_rating, 
            @created_by
        );
        
        -- Capture the newly created trail_id and return via OUTPUT parameter
        SET @new_trail_id = SCOPE_IDENTITY();
        
    END TRY
    BEGIN CATCH
        -- -------------------------------------------------------------------------------------------------
        -- Error Handling Block
        -- Purpose: Capture and display error details for debugging
        -- Information: Error message, severity level, and state
        -- -------------------------------------------------------------------------------------------------
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- *************************************************************************************************
-- SECTION 3: READ PROCEDURE - sp_ReadTrail
-- Purpose: Retrieve trail(s) by ID or return all trails
-- Parameters: @trail_id (NULL returns all trails)
-- Returns: Result set containing trail record(s)
-- Flexibility: Single parameter handles both specific and list queries
-- *************************************************************************************************
CREATE PROCEDURE CW1.sp_ReadTrail
    -- Optional parameter: NULL returns all trails, specific ID returns one trail
    @trail_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- -------------------------------------------------------------------------------------------------
        -- Conditional Query Logic
        -- If trail_id provided: Return specific trail
        -- If trail_id is NULL: Return all trails ordered by creation date
        -- -------------------------------------------------------------------------------------------------
        IF @trail_id IS NOT NULL
        BEGIN
            -- Query for specific trail
            SELECT 
                trail_id, 
                trail_name, 
                difficulty, 
                location, 
                length_km, 
                elevation_gain_m, 
                route_type, 
                description_text, 
                overall_rating, 
                created_by, 
                created_date
            FROM CW1.TRAIL
            WHERE trail_id = @trail_id;
            
            -- Check if trail was found
            -- @@ROWCOUNT returns number of rows affected by last statement
            IF @@ROWCOUNT = 0
            BEGIN
                PRINT 'Warning: No trail found with ID: ' + CAST(@trail_id AS VARCHAR(10));
            END
        END
        ELSE
        BEGIN
            -- Query for all trails
            -- Ordered by created_date DESC to show newest trails first
            SELECT 
                trail_id, 
                trail_name, 
                difficulty, 
                location, 
                length_km, 
                elevation_gain_m, 
                route_type, 
                description_text, 
                overall_rating, 
                created_by, 
                created_date
            FROM CW1.TRAIL
            ORDER BY created_date DESC;
        END
    END TRY
    BEGIN CATCH
        -- Error handling for unexpected issues
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- *************************************************************************************************
-- SECTION 4: UPDATE PROCEDURE - sp_UpdateTrail
-- Purpose: Modify existing trail attributes
-- Parameters: trail_id (required) and fields to update (optional)
-- Design: NULL parameters are not updated, allowing partial updates
-- Validation: Checks trail exists and validates constraint values
-- *************************************************************************************************
CREATE PROCEDURE CW1.sp_UpdateTrail
    -- Required parameter: Trail to update
    @trail_id INT,
    
    -- Optional parameters: NULL means do not update this field
    @trail_name NVARCHAR(255) = NULL,
    @difficulty NVARCHAR(50) = NULL,
    @location NVARCHAR(255) = NULL,
    @length_km DECIMAL(10, 2) = NULL,
    @elevation_gain_m INT = NULL,
    @route_type NVARCHAR(50) = NULL,
    @description_text NVARCHAR(MAX) = NULL,
    @overall_rating DECIMAL(3, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- -------------------------------------------------------------------------------------------------
        -- Validation 1: Verify trail exists
        -- Purpose: Prevent update operation on non-existent record
        -- Error: Raise error if trail_id not found
        -- -------------------------------------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM CW1.TRAIL WHERE trail_id = @trail_id)
        BEGIN
            RAISERROR('Error: Trail with specified ID does not exist', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 2: Check difficulty if provided
        -- Purpose: Ensure updated difficulty matches CHECK constraint
        -- -------------------------------------------------------------------------------------------------
        IF @difficulty IS NOT NULL AND @difficulty NOT IN ('Easy', 'Moderate', 'Hard')
        BEGIN
            RAISERROR('Error: Difficulty must be Easy, Moderate, or Hard', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 3: Check route type if provided
        -- Purpose: Ensure updated route_type matches CHECK constraint
        -- -------------------------------------------------------------------------------------------------
        IF @route_type IS NOT NULL AND @route_type NOT IN ('Loop', 'Out & back', 'Point to point')
        BEGIN
            RAISERROR('Error: Route type must be Loop, Out & back, or Point to point', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Validation 4: Check rating if provided
        -- Purpose: Ensure updated rating is within valid range
        -- -------------------------------------------------------------------------------------------------
        IF @overall_rating IS NOT NULL AND (@overall_rating < 1.00 OR @overall_rating > 5.00)
        BEGIN
            RAISERROR('Error: Overall rating must be between 1.00 and 5.00', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Update Operation
        -- Purpose: Modify trail attributes
        -- ISNULL Function: If parameter is NULL, keep existing value; otherwise use new value
        -- Benefit: Allows partial updates without overwriting existing data
        -- -------------------------------------------------------------------------------------------------
        UPDATE CW1.TRAIL
        SET 
            trail_name = ISNULL(@trail_name, trail_name),
            difficulty = ISNULL(@difficulty, difficulty),
            location = ISNULL(@location, location),
            length_km = ISNULL(@length_km, length_km),
            elevation_gain_m = ISNULL(@elevation_gain_m, elevation_gain_m),
            route_type = ISNULL(@route_type, route_type),
            description_text = ISNULL(@description_text, description_text),
            overall_rating = ISNULL(@overall_rating, overall_rating)
        WHERE trail_id = @trail_id;
        
    END TRY
    BEGIN CATCH
        -- Error handling for unexpected issues
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- *************************************************************************************************
-- SECTION 5: DELETE PROCEDURE - sp_DeleteTrail
-- Purpose: Remove trail and cascade to related features
-- Parameters: @trail_id to delete
-- Cascade: ON DELETE CASCADE automatically removes TRAIL_FEATURE records
-- Validation: Checks trail exists before attempting deletion
-- *************************************************************************************************
CREATE PROCEDURE CW1.sp_DeleteTrail
    @trail_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- -------------------------------------------------------------------------------------------------
        -- Validation: Verify trail exists
        -- Purpose: Prevent delete operation on non-existent record
        -- Error: Raise error if trail_id not found
        -- -------------------------------------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM CW1.TRAIL WHERE trail_id = @trail_id)
        BEGIN
            RAISERROR('Error: Trail with specified ID does not exist', 16, 1);
            RETURN;
        END
        
        -- -------------------------------------------------------------------------------------------------
        -- Delete Operation
        -- Purpose: Remove trail from database
        -- Cascade Effect: ON DELETE CASCADE in TRAIL_FEATURE foreign key automatically removes
        --                 all related feature records, maintaining referential integrity
        -- -------------------------------------------------------------------------------------------------
        DELETE FROM CW1.TRAIL
        WHERE trail_id = @trail_id;
        
    END TRY
    BEGIN CATCH
        -- Error handling for unexpected issues
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- *************************************************************************************************
-- SECTION 6: PROCEDURE TESTING
-- Purpose: Test all CRUD operations with before/after verification
-- Coverage: INSERT, READ, UPDATE, DELETE operations
-- *************************************************************************************************

-- -------------------------------------------------------------------------------------------------
-- TEST 1: INSERT Operation
-- Purpose: Test sp_InsertTrail procedure
-- Steps: Check before state, execute insert, verify after state
-- -------------------------------------------------------------------------------------------------

-- Before INSERT: View current trails
SELECT trail_id, trail_name, difficulty, location, created_by
FROM CW1.TRAIL
ORDER BY trail_id;
GO

-- Execute INSERT procedure
DECLARE @new_id INT;
EXEC CW1.sp_InsertTrail 
    @trail_name = 'Test Trail - Procedure Insert',
    @difficulty = 'Moderate',
    @location = 'Test Location, Devon, England',
    @length_km = 7.5,
    @elevation_gain_m = 250,
    @route_type = 'Loop',
    @description_text = 'Trail inserted via stored procedure for testing.',
    @overall_rating = 4.20,
    @created_by = 2,
    @new_trail_id = @new_id OUTPUT;

SELECT @new_id AS NewTrailID;
GO

-- After INSERT: Verify new trail exists
SELECT trail_id, trail_name, difficulty, location, created_by
FROM CW1.TRAIL
WHERE trail_name = 'Test Trail - Procedure Insert';
GO

-- -------------------------------------------------------------------------------------------------
-- TEST 2: READ Operation
-- Purpose: Test sp_ReadTrail procedure
-- Coverage: Read specific trail and read all trails
-- -------------------------------------------------------------------------------------------------

-- Read specific trail
EXEC CW1.sp_ReadTrail @trail_id = 1;
GO

-- Read all trails
EXEC CW1.sp_ReadTrail;
GO

-- -------------------------------------------------------------------------------------------------
-- TEST 3: UPDATE Operation
-- Purpose: Test sp_UpdateTrail procedure
-- Steps: Check before state, execute update, verify after state
-- -------------------------------------------------------------------------------------------------

-- Before UPDATE: View current state
SELECT trail_id, trail_name, difficulty, overall_rating
FROM CW1.TRAIL
WHERE trail_id = 6;
GO

-- Execute UPDATE procedure
EXEC CW1.sp_UpdateTrail
    @trail_id = 6,
    @trail_name = 'Test Trail - UPDATED',
    @difficulty = 'Hard',
    @overall_rating = 4.75;
GO

-- After UPDATE: Verify changes
SELECT trail_id, trail_name, difficulty, overall_rating
FROM CW1.TRAIL
WHERE trail_id = 6;
GO

-- -------------------------------------------------------------------------------------------------
-- TEST 4: DELETE Operation
-- Purpose: Test sp_DeleteTrail procedure
-- Steps: Check before state, execute delete, verify after state
-- -------------------------------------------------------------------------------------------------

-- Before DELETE: View trail to be deleted
SELECT trail_id, trail_name, difficulty
FROM CW1.TRAIL
WHERE trail_id = 6;
GO

-- Execute DELETE procedure
EXEC CW1.sp_DeleteTrail @trail_id = 6;
GO

-- After DELETE: Verify trail no longer exists
SELECT trail_id, trail_name, difficulty
FROM CW1.TRAIL
WHERE trail_id = 6;
GO