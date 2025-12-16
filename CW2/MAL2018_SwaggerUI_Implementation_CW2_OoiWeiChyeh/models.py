"""
models.py

Defines ORM (Object-Relational Mapping) classes for the CW1 database schema.
Each class represents a table in the database and includes:
- Column definitions with appropriate data types and constraints
- Relationships between tables (foreign keys and backreferences)
- Marshmallow schemas for JSON serialization

Tables implemented:
- USER: System users who create trails
- TRAIL: Hiking trail records with metadata
- TRAIL_FEATURE: Junction table for many-to-many relationship

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from datetime import datetime
from config import db, ma
from marshmallow import fields

# ===================================================================================
# DATABASE MODELS (ORM Classes)
# ===================================================================================

class User(db.Model):
    """
    USER table model representing authenticated users.
    
    This table stores user account information including credentials,
    profile details, and role-based access control data.
    
    Relationships:
    - One user can create many trails (one-to-many via 'trails' backref)
    
    Constraints:
    - email must be unique across all users
    - role is restricted to 'admin' or 'user' via CHECK constraint in database
    """
    
    # Specify the actual table name in the database
    __tablename__ = "USER"
    # Specify the schema (namespace) where this table exists
    __table_args__ = {"schema": "CW1"}

    # Primary key: auto-incrementing integer identifier
    user_id = db.Column(db.Integer, primary_key=True)
    
    # User credentials and contact information
    # unique=True enforces one email per user at database level
    email = db.Column(db.String(255), unique=True, nullable=False)
    
    # Display name shown in the application
    username = db.Column(db.String(100), nullable=False)
    
    # Optional full legal name
    full_name = db.Column(db.String(255))
    
    # Role-based access control field
    # Default value is 'user', admins must be explicitly assigned
    role = db.Column(db.String(50), default="user", nullable=False)
    
    # Timestamp of account creation
    # Uses UTC time to avoid timezone issues
    registration_date = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship definition: links User to Trail table
    # backref creates a reverse reference 'creator' on Trail objects
    # lazy=True means related trails are loaded only when accessed
    trails = db.relationship("Trail", backref="creator", lazy=True)


class Trail(db.Model):
    """
    TRAIL table model representing hiking trail records.
    
    This is the central entity in the system, containing all trail metadata
    including location, difficulty, physical characteristics, and ratings.
    
    Relationships:
    - Each trail is created by exactly one user (many-to-one via created_by FK)
    - Each trail can have many features (one-to-many via 'features' backref)
    
    Constraints:
    - difficulty must be 'Easy', 'Moderate', or 'Hard' (CHECK constraint in DB)
    - route_type must be 'Loop', 'Out & back', or 'Point to point'
    - length_km must be greater than 0
    - overall_rating must be between 1.00 and 5.00
    """
    
    __tablename__ = "TRAIL"
    __table_args__ = {"schema": "CW1"}

    # Primary key: auto-incrementing trail identifier
    trail_id = db.Column(db.Integer, primary_key=True)
    
    # Trail identification and categorization
    trail_name = db.Column(db.String(255), nullable=False)
    
    # Difficulty level: Easy, Moderate, or Hard
    difficulty = db.Column(db.String(50), nullable=False)
    
    # Geographic location description (e.g., "Plymouth, Devon, England")
    location = db.Column(db.String(255), nullable=False)
    
    # Physical trail characteristics
    # DECIMAL(10,2) allows values like 123.45 km
    length_km = db.Column(db.Numeric(10, 2), nullable=False)
    
    # Total elevation gain in meters (optional)
    elevation_gain_m = db.Column(db.Integer)
    
    # Type of trail route pattern
    route_type = db.Column(db.String(50), nullable=False)
    
    # Detailed trail description (TEXT type for long content)
    description_text = db.Column(db.Text)
    
    # Average user rating (DECIMAL(3,2) allows values like 4.75)
    overall_rating = db.Column(db.Numeric(3, 2))
    
    # Timestamp when trail was added to system
    created_date = db.Column(db.DateTime, default=datetime.utcnow)

    # Foreign key enforcing trail ownership
    # References USER.user_id in CW1 schema
    # nullable=False ensures every trail has a creator
    created_by = db.Column(
        db.Integer,
        db.ForeignKey("CW1.USER.user_id"),
        nullable=False
    )
    
    # Relationship to TRAIL_FEATURE junction table
    # cascade='all, delete-orphan' ensures features are deleted when trail is deleted
    features = db.relationship(
        "TrailFeature",
        backref="trail",
        cascade="all, delete-orphan",
        lazy=True
    )


class TrailFeature(db.Model):
    """
    TRAIL_FEATURE junction table implementing many-to-many relationship.
    
    This table resolves the M:N relationship between trails and features.
    A trail can have multiple features (river, forest, historical site, etc.)
    and a feature can appear on multiple trails.
    
    Design pattern: Junction table with composite primary key
    Primary key consists of (trail_id, feature_name) combination
    
    Constraints:
    - Composite PK ensures no duplicate feature entries per trail
    - Foreign key to TRAIL with CASCADE DELETE for automatic cleanup
    """
    
    __tablename__ = "TRAIL_FEATURE"
    __table_args__ = {"schema": "CW1"}

    # First part of composite primary key
    # Foreign key referencing TRAIL table
    trail_id = db.Column(
        db.Integer,
        db.ForeignKey("CW1.TRAIL.trail_id", ondelete="CASCADE"),
        primary_key=True
    )
    
    # Second part of composite primary key
    # Name of the feature (e.g., "River", "Forest", "Historical Site")
    feature_name = db.Column(db.String(100), primary_key=True)
    
    # Optional description providing more detail about the feature
    feature_description = db.Column(db.String(500))


# ===================================================================================
# MARSHMALLOW SCHEMAS (Serialization Layer)
# ===================================================================================

class UserSchema(ma.SQLAlchemyAutoSchema):
    """
    Serialization schema for User model.
    
    Automatically generates JSON representation of User objects.
    Used in API responses to convert database records to JSON.
    """
    
    class Meta:
        # Link this schema to the User model
        model = User
        
        # Enable deserialization: convert JSON to User instances
        load_instance = True
        
        # Use the same database session for ORM operations
        sqla_session = db.session
        
        # Include the 'trails' relationship in serialization
        # This allows API responses to include a user's created trails
        include_relationships = True


class TrailSchema(ma.SQLAlchemyAutoSchema):
    """
    Serialization schema for Trail model.
    
    Includes nested creator information and features list.
    Provides comprehensive trail data in API responses.
    """
    
    # Nested schema: includes full creator details in trail responses
    # This avoids additional API calls to fetch creator information
    creator = fields.Nested(UserSchema, only=["user_id", "username", "email"])
    
    # Nested list of features associated with this trail
    # only=[] specifies which feature fields to include
    features = fields.Nested(
        "TrailFeatureSchema",
        many=True,
        only=["feature_name", "feature_description"]
    )
    
    class Meta:
        model = Trail
        load_instance = True
        sqla_session = db.session
        include_relationships = True
        include_fk = True  # Include foreign key fields in output


class TrailFeatureSchema(ma.SQLAlchemyAutoSchema):
    """
    Serialization schema for TrailFeature junction table.
    
    Typically used as nested schema within TrailSchema rather than standalone.
    """
    
    class Meta:
        model = TrailFeature
        load_instance = True
        sqla_session = db.session


# ===================================================================================
# SCHEMA INSTANCES
# ===================================================================================
# Create reusable schema instances for controllers to use

# Single user serialization
user_schema = UserSchema()

# Multiple users serialization (many=True)
users_schema = UserSchema(many=True)

# Single trail serialization
trail_schema = TrailSchema()

# Multiple trails serialization
trails_schema = TrailSchema(many=True)

# Single feature serialization
trail_feature_schema = TrailFeatureSchema()

# Multiple features serialization
trail_features_schema = TrailFeatureSchema(many=True)