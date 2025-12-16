"""
app.py

Main application entry point for the CW2 Trail REST API.

This module initializes the Connexion application and starts the development server.
Connexion is a framework that builds on Flask to provide:
- Automatic routing based on OpenAPI specification
- Request/response validation against schemas
- Interactive Swagger UI documentation
- Type-safe parameter handling

The application structure follows the microservices pattern where:
- Each service manages its own database (Database Per Service pattern)
- RESTful API design with standard HTTP methods
- JSON for data interchange
- OpenAPI specification as the contract

To run the application:
    python app.py

The server will start on http://localhost:5000
Swagger UI available at: http://localhost:5000/api/ui

Author: BSCS2509254
Module: MAL2018 - Information Management & Retrieval
Date: November 2025
"""

from flask import redirect, url_for, jsonify
from config import connex_app

# Get the underlying Flask app to add custom routes
app = connex_app.app


@app.route('/')
def index():
    """
    Root endpoint - redirects to Swagger UI documentation.
    
    When users visit http://localhost:5000, they are automatically
    redirected to the interactive API documentation at /api/ui
    """
    return redirect('/api/ui')


@app.route('/health')
def health_check():
    """
    Health check endpoint for monitoring and deployment verification.
    
    Returns:
        JSON response indicating service status
    """
    return jsonify({
        "status": "healthy",
        "service": "Trail REST API",
        "version": "1.0.0"
    }), 200


if __name__ == "__main__":
    # Add the OpenAPI specification to the Connexion app
    # This tells Connexion to:
    # 1. Read the swagger.yml file from the specification_dir (set in config.py)
    # 2. Parse the OpenAPI 3.0 specification
    # 3. Create Flask routes for each endpoint defined in the spec
    # 4. Link each route to the corresponding Python function (operationId)
    # 5. Set up automatic request/response validation
    # 6. Generate interactive Swagger UI documentation
    #
    # swagger.yml contains:
    # - All endpoint definitions (/trails, /users, etc.)
    # - Request/response schemas
    # - Validation rules
    # - Documentation text
    connex_app.add_api("swagger.yml")
    
    # Start the Flask development server
    # Parameters:
    # - port=5000: Server listens on port 5000
    # - debug=True: Enable debug mode for development
    #   * Automatic reloading when code changes
    #   * Detailed error messages
    #   * Interactive debugger in browser
    #
    # WARNING: Never use debug=True in production!
    # Debug mode exposes sensitive information and allows code execution
    #
    # Production deployment should use:
    # - WSGI server (Gunicorn, uWSGI)
    # - Reverse proxy (Nginx, Apache)
    # - Environment-based configuration
    # - SSL/TLS certificates
    # - Rate limiting
    # - Authentication/authorization
    print("\n" + "="*70)
    print(" Trail REST API Server Starting...")
    print("="*70)
    print(f" Server:        http://localhost:5000")
    print(f" Swagger UI:    http://localhost:5000/api/ui")
    print(f" Health Check:  http://localhost:5000/health")
    print("="*70 + "\n")
    
    connex_app.run(port=5000, debug=True)
    
    # After starting, the following endpoints are available:
    #
    # ROOT:
    # GET    /                        - Redirects to Swagger UI
    # GET    /health                  - Health check endpoint
    #
    # TRAIL ENDPOINTS:
    # GET    /api/trails              - List all trails
    # POST   /api/trails              - Create new trail
    # GET    /api/trails/{trail_id}   - Get specific trail
    # PATCH  /api/trails/{trail_id}   - Update trail
    # DELETE /api/trails/{trail_id}   - Delete trail
    #
    # FEATURE ENDPOINTS:
    # GET    /api/trails/{trail_id}/features - Get trail features
    #
    # VIEW ENDPOINTS:
    # GET    /api/trails/view         - Get all trails from view
    # GET    /api/trails/view/{id}    - Get specific trail from view
    #
    # USER ENDPOINTS:
    # GET    /api/users               - List all users
    # GET    /api/users/{user_id}     - Get specific user
    #
    # DOCUMENTATION:
    # GET    /api/ui                  - Swagger UI interface