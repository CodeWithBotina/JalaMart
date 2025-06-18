# app/products/routes.py
from flask import render_template, request, current_app
from flask_login import login_required
from app.products import bp
import requests
from config import Config

@bp.route('/')
@login_required
def list_products():
    response = requests.get(
        f"{Config.BACKEND_URL}/api/products",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    products = response.json().get('data', []) if response.status_code == 200 else []
    return render_template('products/list.html', products=products)

@bp.route('/<int:id>')
@login_required
def product_detail(id):
    response = requests.get(
        f"{Config.BACKEND_URL}/api/products/{id}",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    product = response.json().get('data') if response.status_code == 200 else None
    if not product:
        return render_template('404.html'), 404
    return render_template('products/detail.html', product=product)

@bp.route('/search')
@login_required
def search_products():
    query = request.args.get('q', '')
    response = requests.get(
        f"{Config.BACKEND_URL}/api/products/search/{query}",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    products = response.json().get('data', []) if response.status_code == 200 else []
    return render_template('products/search.html', products=products, query=query)

@bp.route('/featured/recent')
@login_required
def featured_products():
    response = requests.get(
        f"{Config.BACKEND_URL}/api/products/featured/recent",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    products = response.json().get('data', []) if response.status_code == 200 else []
    return render_template('products/list.html', products=products, title='Featured Products')

@bp.route('/featured/discounted')
@login_required
def discounted_products():
    response = requests.get(
        f"{Config.BACKEND_URL}/api/products/featured/discounted",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    products = response.json().get('data', []) if response.status_code == 200 else []
    return render_template('products/list.html', products=products, title='Discounted Products')