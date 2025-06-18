# app/__init__.py
from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager

db = SQLAlchemy()
login_manager = LoginManager()
login_manager.login_view = 'auth.login'

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    login_manager.init_app(app)

    # Import models to register the user_loader
    from app import models

    # Register blueprints
    from app.auth import bp as auth_bp
    app.register_blueprint(auth_bp, url_prefix='/auth')

    from app.products import bp as products_bp
    app.register_blueprint(products_bp, url_prefix='/products')

    from app.cart import bp as cart_bp
    app.register_blueprint(cart_bp, url_prefix='/cart')

    from app.orders import bp as orders_bp
    app.register_blueprint(orders_bp, url_prefix='/orders')

    from app.main import bp as main_bp
    app.register_blueprint(main_bp)

    return app