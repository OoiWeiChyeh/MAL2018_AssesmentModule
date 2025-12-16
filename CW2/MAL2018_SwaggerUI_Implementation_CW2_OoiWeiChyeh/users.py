"""
users.py

Controller module for User-related API endpoints.
Implements read-only operations for user management as per CW1 specification.

User operations are limited to retrieval because user creation/modification
should be handled by an external authentication service (as noted in CW1 assumptions).

Endpoints implemented:
- GET /users: Retrieve all users
- GET /users/{user_id}: Retrieve specific user by ID

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from flask import abort
from config import db
from models import User, user_schema, users_schema


def read_all():
    """
    Retrieve all users from the database.
    
    This endpoint returns a complete list of registered users,
    which may be used for:
    - Admin user management interfaces
    - Displaying trail creators
    - Populating dropdown lists for filtering
    
    Returns:
        tuple: (JSON array of user objects, HTTP status code 200)
        
    Response format:
        [
            {
                "user_id": 1,
                "email": "grace@plymouth.ac.uk",
                "username": "grace123",
                "full_name": "Grace Hopper",
                "role": "user",
                "registration_date": "2025-01-01T08:30:00"
            },
            ...
        ]
        
    Error handling:
        - No explicit error handling needed; empty list returned if no users exist
        - Database connection errors propagate to Flask error handler
        
    Performance considerations:
        - For production systems with many users, implement pagination
        - Consider adding query parameters for filtering (role, registration date range)
        - May want to exclude sensitive fields in public API
    """
    
    # Query all users from database using SQLAlchemy ORM
    # User.query.all() generates: SELECT * FROM CW1.USER
    users = User.query.all()
    
    # Serialize the list of User objects to JSON using Marshmallow
    # users_schema.dump() handles the conversion automatically
    return users_schema.dump(users), 200


def read_one(user_id):
    """
    Retrieve a specific user by their unique identifier.
    
    This endpoint provides detailed information about a single user,
    useful for:
    - User profile pages
    - Displaying trail creator information
    - Admin user detail views
    
    Args:
        user_id (int): The unique identifier of the user to retrieve
                       This comes from the URL path parameter
    
    Returns:
        tuple: (JSON user object, HTTP status code 200) if found
        
    Response format:
        {
            "user_id": 1,
            "email": "grace@plymouth.ac.uk",
            "username": "grace123",
            "full_name": "Grace Hopper",
            "role": "user",
            "registration_date": "2025-01-01T08:30:00",
            "trails": [...]  # Nested list of trails created by this user
        }
        
    Raises:
        404 Not Found: If no user exists with the provided user_id
        
    Error response format:
        {
            "detail": "User with ID 999 not found",
            "status": 404,
            "title": "Not Found",
            "type": "about:blank"
        }
        
    Query optimization:
        - Uses filter() instead of filter_by() for consistency with SQLAlchemy docs
        - one_or_none() is more efficient than first() when expecting single result
        - Consider using get() method for primary key lookups: User.query.get(user_id)
    """
    
    # Query database for user with matching user_id
    # User.query.filter() generates: SELECT * FROM CW1.USER WHERE user_id = ?
    # one_or_none() returns the user object or None (raises error if multiple found)
    user = User.query.filter(User.user_id == user_id).one_or_none()
    
    # Check if user exists
    if user is not None:
        # Serialize the User object to JSON and return with 200 OK status
        return user_schema.dump(user), 200
    else:
        # User not found - return 404 error
        # abort() raises an HTTPException that Flask handles automatically
        # The error response includes the message in standard format
        abort(404, f"User with ID {user_id} not found")