"""
features.py

Controller module for Trail Feature management.
Handles the many-to-many relationship between trails and their features.

Features represent points of interest or characteristics of a trail such as:
- Natural features (rivers, forests, cliffs, caves)
- Amenities (parking, restrooms, picnic areas)
- Activity types (dog-friendly, kid-friendly, birding spots)

This module demonstrates junction table operations and M:N relationship management.

Endpoints implemented:
- GET /trails/{trail_id}/features: Get all features for a specific trail

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from flask import abort
from config import db
from models import Trail, TrailFeature, trail_features_schema


def read_by_trail(trail_id):
    """
    Retrieve all features associated with a specific trail.
    
    This endpoint queries the TRAIL_FEATURE junction table to find all
    features linked to the given trail. It's useful for:
    - Displaying trail characteristics on detail pages
    - Filtering trails by features
    - Trail comparison interfaces
    
    Args:
        trail_id (int): The unique identifier of the trail
                        Must correspond to an existing trail in TRAIL table
    
    Returns:
        tuple: (JSON array of feature objects, HTTP status code 200)
        
    Response format:
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
        
    Raises:
        404 Not Found: If trail_id doesn't exist OR trail has no features
        
    Error response:
        {
            "detail": "No features found for trail ID 999",
            "status": 404,
            "title": "Not Found",
            "type": "about:blank"
        }
        
    Database query:
        SELECT feature_name, feature_description
        FROM CW1.TRAIL_FEATURE
        WHERE trail_id = ?
        
    Design notes:
        - Returns 404 if no features exist (rather than empty array)
        - This behavior makes it clear when trail exists but has no features
        - Alternative: return 200 with empty array (more RESTful)
        
    Junction table pattern:
        TRAIL_FEATURE implements M:N relationship:
        - One trail can have many features
        - One feature can appear on many trails
        - Composite PK (trail_id, feature_name) prevents duplicates
        
    Performance considerations:
        - Query is indexed on trail_id (part of PK)
        - Consider eager loading if called frequently with trail data
        - For many features, may want pagination
    """
    
    # First verify the trail exists
    # This provides better error messaging than letting the feature query fail
    # SQL: SELECT 1 FROM CW1.TRAIL WHERE trail_id = ? LIMIT 1
    trail_exists = db.session.query(Trail.trail_id).filter(
        Trail.trail_id == trail_id
    ).first()
    
    if not trail_exists:
        # Trail doesn't exist in database
        abort(404, f"Trail with ID {trail_id} not found")
    
    # Query all features for this trail from junction table
    # SQL: SELECT * FROM CW1.TRAIL_FEATURE WHERE trail_id = ?
    features = TrailFeature.query.filter(
        TrailFeature.trail_id == trail_id
    ).all()
    
    # Check if any features were found
    if not features:
        # Trail exists but has no associated features
        # Could alternatively return 200 with empty array: return [], 200
        abort(404, f"No features found for trail ID {trail_id}")
    
    # Serialize list of TrailFeature objects to JSON
    # Returns array of {feature_name, feature_description} objects
    return trail_features_schema.dump(features), 200