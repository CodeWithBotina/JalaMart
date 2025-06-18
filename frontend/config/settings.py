# jalamart_frontend/config/settings.py
import os

class Config:
    """Base configuration settings for the JalaMart frontend application."""
    SECRET_KEY = os.getenv('FLASK_SECRET_KEY', 'a_very_secret_key_for_development_only')
    BACKEND_API_BASE_URL = os.getenv('BACKEND_API_BASE_URL', 'http://localhost:3000/api')
    # Add other common configurations here
    # For example, pagination settings:
    PRODUCTS_PER_PAGE = 12
    CATEGORIES_PER_PAGE = 10


class DevelopmentConfig(Config):
    """Development specific configuration."""
    DEBUG = True
    # Any other dev-specific settings


class ProductionConfig(Config):
    """Production specific configuration."""
    DEBUG = False
    # Any other production-specific settings for security and performance
    # For example, disable debug mode, set up proper logging, etc.


# Function to get the appropriate configuration based on environment
def get_config():
    env = os.getenv('FLASK_ENV', 'development')
    if env == 'production':
        return ProductionConfig
    return DevelopmentConfig