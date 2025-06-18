# app/orders/routes.py
from flask import render_template, request
from flask_login import login_required, current_user
from app.orders import bp
import requests
from config import Config

@bp.route('/')
@login_required
def list_orders():
    response = requests.get(
        f"{Config.BACKEND_URL}/api/orders/customer/{current_user.id}",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    orders = response.json().get('data', []) if response.status_code == 200 else []
    return render_template('orders/list.html', orders=orders)

@bp.route('/<int:id>')
@login_required
def order_detail(id):
    response = requests.get(
        f"{Config.BACKEND_URL}/api/orders/{id}/details",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    if response.status_code == 200:
        order = response.json().get('data')
        return render_template('orders/detail.html', order=order)
    return render_template('404.html'), 404