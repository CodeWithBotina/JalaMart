# app/main/routes.py
from flask import render_template
from flask_login import login_required
from app.main import bp
import requests
from config import Config

@bp.route('/')
@bp.route('/home')
def index():
    # Get featured products
    featured_response = requests.get(f"{Config.BACKEND_URL}/api/products/featured/recent")
    featured_products = featured_response.json().get('data', []) if featured_response.status_code == 200 else []
    
    # Get discounted products
    discounted_response = requests.get(f"{Config.BACKEND_URL}/api/products/featured/discounted")
    discounted_products = discounted_response.json().get('data', []) if discounted_response.status_code == 200 else []
    
    return render_template(
        'home.html',
        featured_products=featured_products,
        discounted_products=discounted_products
    )