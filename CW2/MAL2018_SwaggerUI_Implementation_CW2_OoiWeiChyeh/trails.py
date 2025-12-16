"""
trails.py

Controller module for Trail-related API endpoints.
Implements complete CRUD (Create, Read, Update, Delete) operations for trail management.

This module serves as the business logic layer between the API specification (swagger.yml)
and the database models. It handles:
- Request validation
- Database operations via SQLAlchemy ORM
- Error handling and appropriate HTTP responses
- Data serialization using Marshmallow schemas

Endpoints implemented:
- GET /trails: Retrieve all trails
- GET /trails/{trail_id}: Retrieve specific trail by ID
- POST /trails: Create new trail
- PATCH /trails/{trail_id}: Update existing trail
- DELETE /trails/{trail_id}: Delete trail

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from flask import abort, make_response
from config import db
from models import Trail, User, trail_schema, trails_schema


def read_all():
    """
    Retrieve all trails from the database.
    
    This endpoint returns the complete trail catalog, ordered by creation date
    (most recent first). Each trail includes nested creator information and features.
    
    Use cases:
    - Trail listing page
    - Search/filter interfaces
    - Admin trail management
    - Data export operations
    
    Returns:
        tuple: (JSON array of trail objects, HTTP status code 200)
        
    Response format:
        [
            {
                "trail_id": 1,
                "trail_name": "Plymbridge Circular",
                "difficulty": "Easy",
                "location": "Plymouth, Devon, England",
                "length_km": 5.2,
                "elevation_gain_m": 147,
                "route_type": "Loop",
                "description_text": "Scenic trail...",
                "overall_rating": 4.7,
                "created_date": "2025-11-01T10:30:00",
                "created_by": 1,
                "creator": {
                    "user_id": 1,
                    "username": "grace123",
                    "email": "grace@plymouth.ac.uk"
                },
                "features": [
                    {
                        "feature_name": "River",
                        "feature_description": "River Plym"
                    }
                ]
            },
            ...
        ]
        
    Performance considerations:
        - For production: implement pagination to handle large datasets
        - Consider adding query parameters for filtering (difficulty, location, rating)
        - May need caching for frequently accessed trail lists
        - order_by() creates SQL: ORDER BY created_date DESC
    """
    
    # Query all trails ordered by most recent first
    # Trail.query generates SELECT statement for entire TRAIL table
    # order_by() adds ORDER BY clause to SQL query
    trails = Trail.query.order_by(Trail.created_date.desc()).all()
    
    # Serialize list of Trail objects to JSON
    # trails_schema automatically includes nested creator and features
    return trails_schema.dump(trails), 200


def read_one(trail_id):
    """
    Retrieve a specific trail by its unique identifier.
    
    Returns complete trail information including creator details and
    all associated features. Used for trail detail pages.
    
    Args:
        trail_id (int): Unique identifier from URL path parameter
                        Must be a positive integer
    
    Returns:
        tuple: (JSON trail object, HTTP status code 200) if found
        
    Response format:
        {
            "trail_id": 1,
            "trail_name": "Plymbridge Circular",
            "difficulty": "Easy",
            "location": "Plymouth, Devon, England",
            "length_km": 5.2,
            "elevation_gain_m": 147,
            "route_type": "Loop",
            "description_text": "Scenic trail around Plymbridge...",
            "overall_rating": 4.7,
            "created_date": "2025-11-01T10:30:00",
            "created_by": 1,
            "creator": {
                "user_id": 1,
                "username": "grace123",
                "email": "grace@plymouth.ac.uk"
            },
            "features": [
                {"feature_name": "River", "feature_description": "River Plym"},
                {"feature_name": "Forest", "feature_description": "Woodland area"}
            ]
        }
        
    Raises:
        404 Not Found: If trail_id does not exist in database
        
    Error response format:
        {
            "detail": "Trail with ID 999 not found",
            "status": 404,
            "title": "Not Found",
            "type": "about:blank"
        }
        
    Database query optimization:
        - Uses filter() with primary key for indexed lookup
        - one_or_none() more explicit than first() for single-result queries
        - Alternative: Trail.query.get(trail_id) for direct PK lookup
    """
    
    # Query database for trail with matching trail_id
    # SQL: SELECT * FROM CW1.TRAIL WHERE trail_id = ?
    trail = Trail.query.filter(Trail.trail_id == trail_id).one_or_none()
    
    # Verify trail exists before returning
    if trail is not None:
        # Serialize Trail object with nested relationships
        return trail_schema.dump(trail), 200
    else:
        # Return 404 error with descriptive message
        abort(404, f"Trail with ID {trail_id} not found")


def create(body):
    """
    Create a new trail record in the database.
    
    This endpoint validates the request data, verifies the creator exists,
    and inserts a new trail record. Returns the created trail with generated ID.
    
    Args:
        body (dict): Trail data from request body, validated against swagger.yml schema
                     Must include: trail_name, difficulty, location, length_km, route_type, email
                     Optional: elevation_gain_m, description_text, overall_rating
    
    Request body format:
        {
            "trail_name": "New Forest Trail",
            "difficulty": "Moderate",
            "location": "Devon, England",
            "length_km": 8.5,
            "elevation_gain_m": 200,
            "route_type": "Loop",
            "description_text": "Beautiful forest walk...",
            "overall_rating": 4.5,
            "email": "grace@plymouth.ac.uk"
        }
    
    Returns:
        tuple: (JSON trail object with new trail_id, HTTP status code 201)
        
    Response format:
        {
            "trail_id": 6,
            "trail_name": "New Forest Trail",
            "difficulty": "Moderate",
            ...
            "created_by": 1,
            "created_date": "2025-11-17T14:30:00"
        }
        
    Raises:
        404 Not Found: If email does not match any existing user
        400 Bad Request: If validation fails (handled by Connexion via swagger.yml)
        
    Error scenarios:
        1. Non-existent user email -> 404
        2. Missing required fields -> 400 (Connexion validates)
        3. Invalid difficulty value -> 400 (Connexion validates)
        4. Invalid route_type -> 400 (Connexion validates)
        5. Negative length_km -> 400 (Connexion validates)
        
    Business logic:
        - Email is used to identify trail creator (matches CW1 specification)
        - User must exist before trail can be created (referential integrity)
        - created_date is auto-generated using database default
        - trail_id is auto-generated using IDENTITY(1,1)
        
    Transaction handling:
        - db.session.add() stages the insert
        - db.session.commit() executes the transaction
        - Automatic rollback occurs if any error is raised
    """
    
    # Extract creator email from request body
    # This field is used to link trail to existing user
    email = body.get("email")
    
    # Verify that a user with this email exists
    # SQL: SELECT * FROM CW1.USER WHERE email = ?
    existing_user = User.query.filter(User.email == email).one_or_none()
    
    if existing_user is None:
        # User not found - cannot create trail without valid creator
        # Return 404 with helpful error message
        abort(404, f"User with email {email} does not exist")
    
    # Remove email from body dictionary as it's not a Trail table field
    # It was only used for user lookup
    body.pop("email", None)
    
    # Add the user_id foreign key to the trail data
    # This establishes the relationship between trail and creator
    body["created_by"] = existing_user.user_id
    
    # Create new Trail object from validated request data
    # trail_schema.load() deserializes JSON to Trail model instance
    # session parameter ensures object is bound to current database session
    new_trail = trail_schema.load(body, session=db.session)
    
    # Stage the new trail for insertion
    # This doesn't execute SQL yet, just prepares the transaction
    db.session.add(new_trail)
    
    # Commit transaction to database
    # SQL: INSERT INTO CW1.TRAIL (...) VALUES (...)
    # Database generates trail_id and created_date automatically
    db.session.commit()
    
    # Serialize the newly created trail (now with trail_id) and return
    # 201 Created status indicates successful resource creation
    return trail_schema.dump(new_trail), 201


def update(trail_id, body):
    """
    Update an existing trail record with partial or complete data.
    
    Implements PATCH semantics: only provided fields are updated,
    omitted fields remain unchanged. Validates creator email if provided.
    
    Args:
        trail_id (int): ID of trail to update (from URL path)
        body (dict): Partial or complete trail data from request body
                     All fields optional except those being updated
    
    Request body examples:
        # Update only difficulty
        {"difficulty": "Hard"}
        
        # Update multiple fields
        {
            "trail_name": "Updated Trail Name",
            "overall_rating": 4.8,
            "description_text": "New description..."
        }
        
        # Change creator (requires valid email)
        {"email": "ada@plymouth.ac.uk"}
    
    Returns:
        tuple: (JSON trail object with updates, HTTP status code 200)
        
    Raises:
        404 Not Found: If trail_id doesn't exist OR email doesn't match any user
        400 Bad Request: If validation fails (Connexion validates types/enums)
        
    Update process:
        1. Verify trail exists in database
        2. If email provided, verify new creator exists
        3. Update created_by if email was provided
        4. Merge updated data with existing trail
        5. Commit changes to database
        6. Return updated trail object
        
    Important notes:
        - PATCH is idempotent: applying same update multiple times has same effect
        - Foreign key constraints are validated by database
        - CHECK constraints (difficulty, route_type) enforced by database
        - Partial updates preserve existing data for omitted fields
        
    Example SQL generated:
        UPDATE CW1.TRAIL
        SET difficulty = 'Hard', overall_rating = 4.8
        WHERE trail_id = 3
    """
    
    # First, verify the trail exists
    # SQL: SELECT * FROM CW1.TRAIL WHERE trail_id = ?
    existing_trail = Trail.query.filter(Trail.trail_id == trail_id).one_or_none()
    
    if existing_trail is None:
        # Trail not found - cannot update non-existent resource
        abort(404, f"Trail with ID {trail_id} not found")
    
    # Handle creator change if email is provided
    if "email" in body:
        email = body.get("email")
        
        # Verify new creator exists
        # SQL: SELECT * FROM CW1.USER WHERE email = ?
        new_creator = User.query.filter(User.email == email).one_or_none()
        
        if new_creator is None:
            # New creator email not found in user table
            abort(404, f"User with email {email} does not exist")
        
        # Update the foreign key with new creator's user_id
        body["created_by"] = new_creator.user_id
        
        # Remove email from body as it's not a Trail table column
        body.pop("email", None)
    
    # Load update data and merge with existing trail
    # partial=True allows incomplete data (PATCH semantics)
    # session ensures object is bound to current database session
    update_trail = trail_schema.load(body, session=db.session, partial=True)
    
    # Update existing trail attributes with new values
    # Only fields present in body are updated
    for key, value in body.items():
        setattr(existing_trail, key, value)
    
    # Merge ensures existing_trail is tracked by session
    db.session.merge(existing_trail)
    
    # Commit changes to database
    # SQL: UPDATE CW1.TRAIL SET ... WHERE trail_id = ?
    db.session.commit()
    
    # Return updated trail with 200 OK status
    return trail_schema.dump(existing_trail), 200


def delete(trail_id):
    """
    Delete a trail record from the database.
    
    Removes the trail and all associated features (via CASCADE DELETE).
    This is a destructive operation that cannot be undone.
    
    Args:
        trail_id (int): ID of trail to delete (from URL path)
    
    Returns:
        tuple: (Success message, HTTP status code 200)
        
    Response format:
        {
            "message": "Trail with ID 3 successfully deleted"
        }
        
    Raises:
        404 Not Found: If trail_id doesn't exist
        
    Cascade behavior:
        - TRAIL_FEATURE records with matching trail_id are automatically deleted
        - This is enforced by FK_TrailFeature_Trail foreign key with ON DELETE CASCADE
        - No orphan feature records can exist after trail deletion
        
    Database operations:
        1. DELETE FROM CW1.TRAIL_FEATURE WHERE trail_id = ? (automatic)
        2. DELETE FROM CW1.TRAIL WHERE trail_id = ?
        
    Security considerations:
        - In production, implement authorization checks
        - Only trail creator or admin should be allowed to delete
        - Consider soft deletes (marking as deleted) instead of hard deletes
        - May want to archive trail data before deletion
        
    Alternative implementations:
        - Return 204 No Content instead of 200 with message
        - Return the deleted trail object for client confirmation
        - Implement soft delete with 'is_deleted' flag
    """
    
    # Query for trail to be deleted
    # SQL: SELECT * FROM CW1.TRAIL WHERE trail_id = ?
    existing_trail = Trail.query.filter(Trail.trail_id == trail_id).one_or_none()
    
    if existing_trail is None:
        # Trail not found - cannot delete non-existent resource
        abort(404, f"Trail with ID {trail_id} not found")
    
    # Mark trail for deletion
    # This also triggers cascade delete for related TRAIL_FEATURE records
    db.session.delete(existing_trail)
    
    # Commit transaction to execute deletion
    # SQL executes both DELETE statements (TRAIL_FEATURE first due to FK)
    db.session.commit()
    
    # Return success message with 200 OK status
    # make_response creates a proper Flask Response object
    return make_response(
        {"message": f"Trail with ID {trail_id} successfully deleted"},
        200
    )