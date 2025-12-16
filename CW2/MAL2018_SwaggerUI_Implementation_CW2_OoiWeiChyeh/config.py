"""
config.py

Central configuration module for the Trail REST API.
This module is responsible for:
- Initializing the Connexion application (Swagger-first framework)
- Configuring SQLAlchemy database connection to Azure SQL Edge / SQL Server
- Setting up Marshmallow for object serialization
- Defining application-wide settings

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

import pathlib
import connexion
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from urllib.parse import quote_plus

# -----------------------------------------------------------------------------------
# Base Directory Configuration
# -----------------------------------------------------------------------------------
# Get the absolute path of the directory containing this config file
# This is used to locate the swagger.yml specification file
BASE_DIR = pathlib.Path(__file__).parent.resolve()

# -----------------------------------------------------------------------------------
# Connexion Application Initialization
# -----------------------------------------------------------------------------------
# Connexion is a framework built on top of Flask that handles OpenAPI specifications
# It automatically validates requests/responses against the API specification
connex_app = connexion.App(__name__, specification_dir=BASE_DIR)

# Extract the underlying Flask application instance
# This is needed for direct Flask configuration and database setup
app = connex_app.app

# -----------------------------------------------------------------------------------
# Database Connection Configuration
# -----------------------------------------------------------------------------------
# Connection string for Azure SQL Edge running in Docker
# Components:
# - DRIVER: ODBC Driver 18 is required for SQL Server connectivity
# - SERVER: localhost indicates the database is running on the same machine
# - DATABASE: COMP2001_Test is the database name from CW1 specification
# - UID/PWD: SQL Server authentication credentials
# - TrustServerCertificate: Required for local development with self-signed certificates
connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=COMP2001_Test;"
    "UID=SA;"
    "PWD=YourStrong!Passw0rd;"
    "TrustServerCertificate=yes;"
)

# SQLAlchemy requires a properly formatted database URI
# Format: mssql+pyodbc:///?odbc_connect=<encoded_connection_string>
# The connection string must be URL-encoded to handle special characters
app.config["SQLALCHEMY_DATABASE_URI"] = (
    "mssql+pyodbc:///?odbc_connect=" + quote_plus(connection_string)
)

# Disable SQLAlchemy's event system for tracking modifications
# This feature adds overhead and is not needed for this application
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# -----------------------------------------------------------------------------------
# ORM and Serialization Layer Initialization
# -----------------------------------------------------------------------------------
# SQLAlchemy: Object-Relational Mapping library
# Maps Python classes to database tables and handles SQL generation
db = SQLAlchemy(app)

# Marshmallow: Object serialization/deserialization library
# Converts Python objects to JSON (and vice versa) for API responses
ma = Marshmallow(app)