# app/cart/routes.py
from flask import render_template, request, flash, redirect, url_for
from flask_login import login_required
from app.cart import bp
import requests
from config import Config

@bp.route('/')
@login_required
def view_cart():
    response = requests.get(
        f"{Config.BACKEND_URL}/api/cart",
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    if response.status_code == 200:
        items = response.json().get('data', [])
        total = sum(item['precio_unitario'] * item['cantidad'] for item in items)
        return render_template('cart/view.html', items=items, total=total)
    return render_template('cart/view.html', items=[], total=0)

@bp.route('/add', methods=['POST'])
@login_required
def add_to_cart():
    product_id = request.form.get('product_id')
    quantity = request.form.get('quantity', 1)
    
    response = requests.post(
        f"{Config.BACKEND_URL}/api/cart",
        json={'id_producto': product_id, 'cantidad': quantity},
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    
    if response.status_code == 200:
        flash('Product added to cart', 'success')
    else:
        flash('Failed to add product to cart', 'danger')
    
    return redirect(request.referrer or url_for('products.list_products'))

@bp.route('/checkout', methods=['POST'])
@login_required
def checkout():
    shipping_address = request.form.get('shipping_address')
    payment_method = request.form.get('payment_method')
    
    response = requests.post(
        f"{Config.BACKEND_URL}/api/cart/checkout",
        json={
            'direccion_envio': shipping_address,
            'metodo_pago': payment_method
        },
        headers={'Authorization': f'Bearer {request.cookies.get("access_token")}'}
    )
    
    if response.status_code == 201:
        flash('Order placed successfully!', 'success')
        return redirect(url_for('orders.list_orders'))
    else:
        flash('Failed to place order', 'danger')
        return redirect(url_for('cart.view_cart'))