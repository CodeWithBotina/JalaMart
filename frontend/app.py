# jalamart_frontend/app.py (Updated)
import os
from flask import Flask, render_template, session, redirect, url_for, flash, request
from dotenv import load_dotenv
from datetime import datetime # Import datetime for current year in footer

# Load environment variables
load_dotenv()

def create_app():
    app = Flask(__name__,
                static_folder='static',
                template_folder='templates')

    # Configuration
    app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'default_secret_key')
    app.config['BACKEND_API_BASE_URL'] = os.getenv('BACKEND_API_BASE_URL', 'http://localhost:3000/api')

    # Import and register blueprints
    from views.public_views import public_bp
    from views.auth_views import auth_bp
    from views.user_views import user_bp
    from views.admin_views import admin_bp # Will be implemented next

    app.register_blueprint(public_bp)
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(user_bp, url_prefix='/user')
    app.register_blueprint(admin_bp, url_prefix='/admin') # Register admin blueprint

    # Custom Error Handlers
    @app.errorhandler(400)
    def bad_request_error(error):
        return render_template('errors/400.html'), 400

    @app.errorhandler(401)
    def unauthorized_error(error):
        return render_template('errors/401.html'), 401

    @app.errorhandler(403)
    def forbidden_error(error):
        return render_template('errors/403.html'), 403

    @app.errorhandler(404)
    def not_found_error(error):
        return render_template('errors/404.html'), 404

    @app.errorhandler(500)
    def internal_server_error(error):
        return render_template('errors/500.html'), 500

    @app.context_processor
    def inject_user_and_cart_count():
        """
        Injects user session data and cart item count into all templates.
        This allows access to `current_user` and `cart_item_count` globally.
        Also injects `now` for dynamic year in footer.
        """
        current_user = session.get('user')
        cart_item_count = session.get('cart_item_count', 0)
        return dict(current_user=current_user, cart_item_count=cart_item_count, now=datetime.utcnow())

    # Custom Jinja2 filter for date formatting
    @app.template_filter('dateformat')
    def format_datetime(value, format="%Y-%m-%d %H:%M"):
        if value is None:
            return ""
        # Assuming the date comes as a string from the backend, parse it first
        # Example: "2025-06-17T15:35:27.000Z" (ISO format)
        if isinstance(value, str):
            try:
                # Handle potential timezone info and strip it for simple parsing
                if 'T' in value and 'Z' in value: # ISO format with Z
                    dt_object = datetime.strptime(value.split('.')[0], "%Y-%m-%dT%H:%M:%S")
                elif ' ' in value and '-' in value: # YYYY-MM-DD HH:MM:SS (PostgreSQL timestamp without time zone)
                     dt_object = datetime.strptime(value.split('.')[0], "%Y-%m-%d %H:%M:%S")
                else: # Fallback for other formats, or if already a datetime object
                    dt_object = datetime.fromisoformat(value.replace('Z', '+00:00')) # Handles Z for UTC
            except ValueError:
                return value # Return original value if parsing fails
        elif isinstance(value, datetime):
            dt_object = value
        else:
            return value # Return original value if not a string or datetime

        return dt_object.strftime(format)


    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)