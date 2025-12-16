"""
views.py

Controller module for database view operations.
Provides read-only access to the vw_TrailsWithCreator view.

Database views offer several advantages:
- Pre-joined data reduces API call complexity
- Consistent data presentation across different endpoints
- Encapsulates complex queries in database layer
- Performance optimization through materialized views (if needed)

The vw_TrailsWithCreator view combines TRAIL and USER tables,
providing complete trail information with creator details in a single query.

View definition (from CW1):
    CREATE VIEW CW1.vw_TrailsWithCreator AS
    SELECT 
        t.trail_id,
        t.trail_name,
        t.difficulty,
        t.location,
        t.length_km,
        t.route_type,
        t.overall_rating,
        u.username AS creator_username,
        u.email AS creator_email,
        u.role AS creator_role,
        DATEDIFF(day, t.created_date, GETDATE()) AS days_since_created
    FROM CW1.TRAIL t
    INNER JOIN CW1.USER u ON t.created_by = u.user_id

Endpoints implemented:
- GET /trails/view: Get all trails with creator info from view

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from flask import abort
from config import db
from sqlalchemy import text


def read_all():
    """
    Retrieve all trails with creator information from database view.
    
    This endpoint queries the vw_TrailsWithCreator view, which provides
    a pre-joined dataset combining trail and user information. The view
    also calculates derived fields like days_since_created.
    
    Use cases:
    - Trail listing pages that need creator information
    - Reports showing trail activity and ownership
    - Dashboard widgets displaying recent trails
    - Data export for analytics
    
    Returns:
        tuple: (JSON array of trail+creator objects, HTTP status code 200)
        
    Response format:
        [
            {
                "trail_id": 1,
                "trail_name": "Plymbridge Circular",
                "difficulty": "Easy",
                "location": "Plymouth, Devon, England",
                "length_km": 5.2,
                "route_type": "Loop",
                "overall_rating": 4.7,
                "creator_username": "grace123",
                "creator_email": "grace@plymouth.ac.uk",
                "creator_role": "user",
                "days_since_created": 15
            },
            ...
        ]
        
    Advantages of using views:
        1. Single query replaces join logic in application code
        2. View definition can be updated without changing API code
        3. Database can optimize view queries independently
        4. Consistent data transformation across all consumers
        5. Derived fields (days_since_created) calculated once
        
    Performance considerations:
        - Views are not materialized, so query runs on each request
        - For high-traffic endpoints, consider:
          * Materialized views (periodic refresh)
          * Caching layer (Redis, Memcached)
          * Pagination for large result sets
        - Indexed columns in base tables improve view performance
        
    Error handling:
        - Empty result set returns empty array (not 404)
        - Database connection errors propagate to Flask handler
        - View must exist or query will fail with SQL error
        
    Alternative implementations:
        - Add filtering parameters (difficulty, location, creator)
        - Implement pagination with OFFSET/FETCH
        - Add sorting options (by rating, date, length)
        - Support field selection to reduce payload size
    """
    
    # Execute raw SQL query against database view
    # text() function is SQLAlchemy's way to safely execute raw SQL
    # This prevents SQL injection while allowing direct SQL syntax
    result = db.session.execute(
        text("SELECT * FROM CW1.vw_TrailsWithCreator")
    ).fetchall()
    
    # Convert result rows to list of dictionaries
    # row._mapping provides column name to value mapping
    # This creates JSON-serializable dictionaries from database rows
    #
    # Example row._mapping:
    # {
    #     'trail_id': 1,
    #     'trail_name': 'Plymbridge Circular',
    #     'difficulty': 'Easy',
    #     ...
    # }
    trails_with_creators = [dict(row._mapping) for row in result]
    
    # Return serialized data with 200 OK status
    # Flask automatically converts list of dicts to JSON
    return trails_with_creators, 200


def read_one(trail_id):
    """
    Retrieve a specific trail with creator info from database view.
    
    Filters the vw_TrailsWithCreator view to return a single trail.
    More efficient than querying the full view and filtering in Python.
    
    Args:
        trail_id (int): Unique identifier of trail to retrieve
    
    Returns:
        tuple: (JSON trail object with creator info, HTTP status code 200)
        
    Response format:
        {
            "trail_id": 1,
            "trail_name": "Plymbridge Circular",
            "difficulty": "Easy",
            "location": "Plymouth, Devon, England",
            "length_km": 5.2,
            "route_type": "Loop",
            "overall_rating": 4.7,
            "creator_username": "grace123",
            "creator_email": "grace@plymouth.ac.uk",
            "creator_role": "user",
            "days_since_created": 15
        }
        
    Raises:
        404 Not Found: If trail_id doesn't exist
        
    Error response:
        {
            "detail": "Trail with ID 999 not found in view",
            "status": 404,
            "title": "Not Found",
            "type": "about:blank"
        }
        
    SQL generated:
        SELECT * FROM CW1.vw_TrailsWithCreator WHERE trail_id = ?
        
    Benefits over direct table query:
        - Pre-joined data eliminates separate user query
        - Includes computed field (days_since_created)
        - Consistent with read_all() behavior
        - Database handles join optimization
    """
    
    # Execute parameterized query against view
    # :trail_id is a named parameter binding (prevents SQL injection)
    result = db.session.execute(
        text("SELECT * FROM CW1.vw_TrailsWithCreator WHERE trail_id = :trail_id"),
        {"trail_id": trail_id}
    ).fetchone()
    
    # Check if trail was found
    if result is None:
        # No trail with this ID exists (or was deleted)
        abort(404, f"Trail with ID {trail_id} not found in view")
    
    # Convert single row to dictionary and return
    return dict(result._mapping), 200