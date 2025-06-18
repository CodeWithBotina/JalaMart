# jalamart_frontend/views/user_views.py
from flask import Blueprint, render_template, redirect, url_for, flash, session, request
from utils.api_client import APIClient, APIError
from utils.decorators import login_required
from utils.forms import ProfileUpdateForm, ChangePasswordForm

# Create a Blueprint for user routes
user_bp = Blueprint('user_bp', __name__)

@user_bp.route('/dashboard')
@login_required
def user_dashboard():
    """
    Renders the user dashboard with profile information.
    (Corresponds to Wireframe Page 8)
    """
    api = APIClient()
    user_id_from_session = session['user']['id_cliente'] # Use id_cliente for customer profile

    customer_profile = None
    try:
        response = api.get(f'/customers/{user_id_from_session}')
        if response.get('success'):
            customer_profile = response.get('data')
        else:
            flash(response.get('message', 'Could not load profile data.'), 'error')
    except APIError as e:
        flash(f"Error loading user profile: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('user/dashboard.html', customer_profile=customer_profile)

@user_bp.route('/profile/edit', methods=['GET', 'POST'])
@login_required
def edit_profile():
    """
    Allows the user to edit their profile information.
    """
    api = APIClient()
    user_id_from_session = session['user']['id_cliente']
    customer_profile = None

    try:
        # Fetch current profile data
        profile_response = api.get(f'/customers/{user_id_from_session}')
        if profile_response.get('success'):
            customer_profile = profile_response.get('data')
        else:
            flash(profile_response.get('message', 'Failed to load profile for editing.'), 'error')
            return redirect(url_for('user_bp.user_dashboard'))
    except APIError as e:
        flash(f"Error loading profile for editing: {e.message}", 'error')
        return redirect(url_for('user_bp.user_dashboard'))
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
        return redirect(url_for('user_bp.user_dashboard'))

    form = ProfileUpdateForm(obj=customer_profile) # Populate form with existing data

    if form.validate_on_submit():
        updated_data = {
            'nombre': form.nombre.data,
            'apellido': form.apellido.data,
            'telefono': form.telefono.data,
            'direccion': form.direccion.data,
            # 'receive_notifications': form.receive_notifications.data # Not directly mapped to DB
        }
        try:
            update_response = api.put(f'/customers/{user_id_from_session}', updated_data)
            if update_response.get('success'):
                flash('Profile updated successfully!', 'success')
                # Update session user data if email/name changes (optional, depends on what's displayed in header)
                session['user']['email'] = session['user']['email'] # Email cannot be changed via this route
                # For example, if you stored name in session: session['user']['name'] = form.nombre.data
                return redirect(url_for('user_bp.user_dashboard'))
            else:
                flash(update_response.get('message', 'Failed to update profile.'), 'error')
        except APIError as e:
            flash(f"Failed to update profile: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred during profile update: {str(e)}", 'error')

    return render_template('user/edit_profile.html', form=form, customer_profile=customer_profile)

@user_bp.route('/password/change', methods=['GET', 'POST'])
@login_required
def change_password():
    """
    Allows the user to change their password.
    """
    form = ChangePasswordForm()
    if form.validate_on_submit():
        api = APIClient()
        user_id_from_session = session['user']['id_cliente'] # Use id_cliente for customer profile

        current_password = form.current_password.data
        new_password = form.new_password.data

        try:
            response = api.put(f'/customers/{user_id_from_session}/password',
                               {'currentPassword': current_password, 'newPassword': new_password})
            if response.get('success'):
                flash('Password changed successfully!', 'success')
                return redirect(url_for('user_bp.user_dashboard'))
            else:
                flash(response.get('message', 'Failed to change password.'), 'error')
        except APIError as e:
            flash(f"Password change failed: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred during password change: {str(e)}", 'error')

    return render_template('user/change_password.html', form=form)

@user_bp.route('/cart')
@login_required
def view_cart():
    """
    Renders the shopping cart page, displaying items in the cart.
    (Corresponds to Wireframe Page 7)
    """
    api = APIClient()
    cart_items = []
    total_amount = 0.0

    try:
        response = api.get('/cart') # This endpoint gets active cart items for the logged-in user
        if response.get('success'):
            cart_items = response.get('data', [])
            # Calculate total amount (backend also calculates, but for display consistency)
            total_amount = sum(item['precio_total'] for item in cart_items)
            session['cart_item_count'] = len(cart_items) # Update cart count in session
        else:
            flash(response.get('message', 'Could not load cart items.'), 'error')
    except APIError as e:
        flash(f"Error loading cart: {e.message}", 'error')
        # If cart cannot be loaded, ensure session cart count is reset
        session['cart_item_count'] = 0
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
        session['cart_item_count'] = 0

    return render_template('public/cart.html', cart_items=cart_items, total_amount=total_amount)

@user_bp.route('/cart/add', methods=['POST'])
@login_required
def add_to_cart():
    """
    Adds a product to the user's cart.
    This route is called via JavaScript from the product detail page.
    """
    api = APIClient()
    data = request.get_json()
    product_id = data.get('id_producto')
    quantity = data.get('cantidad')

    if not product_id or not quantity:
        return {'success': False, 'message': 'Missing product ID or quantity.'}, 400

    try:
        # The backend /cart endpoint handles checking for active cart and adding/updating items.
        response = api.post('/cart', {'id_producto': product_id, 'cantidad': quantity})
        if response.get('success'):
            # Update cart item count in session
            session['cart_item_count'] = len(response.get('data', []))
            return {'success': True, 'message': 'Product added to cart!', 'cart_count': session['cart_item_count']}, 200
        else:
            return {'success': False, 'message': response.get('message', 'Failed to add to cart.')}, 400
    except APIError as e:
        return {'success': False, 'message': e.message}, e.status_code
    except Exception as e:
        return {'success': False, 'message': f"An unexpected error occurred: {str(e)}"}, 500

@user_bp.route('/cart/update/<int:item_id>', methods=['POST'])
@login_required
def update_cart_item(item_id):
    """
    Updates the quantity of a specific item in the cart.
    This route is called via JavaScript from the cart page.
    """
    api = APIClient()
    data = request.get_json()
    quantity = data.get('cantidad')

    if quantity is None:
        return {'success': False, 'message': 'Missing quantity.'}, 400

    try:
        response = api.put(f'/cart/{item_id}', {'cantidad': quantity})
        if response.get('success'):
            session['cart_item_count'] = len(response.get('data', []))
            return {'success': True, 'message': 'Cart updated successfully!', 'cart_count': session['cart_item_count']}, 200
        else:
            return {'success': False, 'message': response.get('message', 'Failed to update cart.')}, 400
    except APIError as e:
        return {'success': False, 'message': e.message}, e.status_code
    except Exception as e:
        return {'success': False, 'message': f"An unexpected error occurred: {str(e)}"}, 500

@user_bp.route('/cart/remove/<int:item_id>', methods=['POST'])
@login_required
def remove_cart_item(item_id):
    """
    Removes a specific item from the cart.
    This route is called via JavaScript from the cart page.
    """
    api = APIClient()
    try:
        response = api.delete(f'/cart/{item_id}')
        if response.get('success'):
            session['cart_item_count'] = len(response.get('data', []))
            return {'success': True, 'message': 'Item removed from cart.', 'cart_count': session['cart_item_count']}, 200
        else:
            return {'success': False, 'message': response.get('message', 'Failed to remove item.')}, 400
    except APIError as e:
        return {'success': False, 'message': e.message}, e.status_code
    except Exception as e:
        return {'success': False, 'message': f"An unexpected error occurred: {str(e)}"}, 500

@user_bp.route('/checkout', methods=['GET', 'POST'])
@login_required
def checkout():
    """
    Handles the checkout process, converting the cart to an order.
    Presents a simplified checkout form for address and payment method.
    """
    api = APIClient()
    cart_items = []
    total_amount = 0.0

    # First, fetch cart items to display
    try:
        cart_response = api.get('/cart')
        if cart_response.get('success'):
            cart_items = cart_response.get('data', [])
            total_amount = sum(item['precio_total'] for item in cart_items)
            if not cart_items:
                flash("Your cart is empty. Please add items before checking out.", 'info')
                return redirect(url_for('public_bp.home'))
        else:
            flash(cart_response.get('message', 'Could not load cart for checkout.'), 'error')
            return redirect(url_for('public_bp.home'))
    except APIError as e:
        flash(f"Error loading cart for checkout: {e.message}", 'error')
        return redirect(url_for('public_bp.home'))
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
        return redirect(url_for('public_bp.home'))


    if request.method == 'POST':
        # In a real app, you'd have a form for address and payment details
        # For simplicity, we'll use placeholder data or user's default address
        user_id_from_session = session['user']['id_cliente']
        customer_profile = None
        try:
            profile_response = api.get(f'/customers/{user_id_from_session}')
            if profile_response.get('success'):
                customer_profile = profile_response.get('data')
        except APIError as e:
            flash(f"Could not retrieve shipping address: {e.message}", 'error')
            return render_template('user/checkout.html', cart_items=cart_items, total_amount=total_amount)

        shipping_address = customer_profile.get('direccion') if customer_profile else "Default Address"
        payment_method = request.form.get('payment_method', 'Credit Card') # Get from form input

        order_data = {
            'direccion_envio': shipping_address,
            'metodo_pago': payment_method,
            # Backend calculates total, subtotal, taxes based on cart items
            # So, we don't send `total`, `subtotal`, `impuestos` from here
            # but provide cart items if the backend needs them to recalculate
            'items': [{'id_producto': item['id_producto'], 'cantidad': item['cantidad'], 'precio_unitario': item['precio_unitario']} for item in cart_items]
        }

        try:
            order_response = api.post('/cart/checkout', order_data)
            if order_response.get('success'):
                flash('Order placed successfully!', 'success')
                session['cart_item_count'] = 0 # Clear cart count after successful checkout
                return redirect(url_for('user_bp.view_orders')) # Redirect to order history
            else:
                flash(order_response.get('message', 'Failed to place order.'), 'error')
        except APIError as e:
            flash(f"Order placement failed: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred during checkout: {str(e)}", 'error')

    return render_template('user/checkout.html', cart_items=cart_items, total_amount=total_amount)


@user_bp.route('/orders')
@login_required
def view_orders():
    """
    Displays the logged-in user's order history.
    """
    api = APIClient()
    user_id_from_session = session['user']['id_cliente']
    orders = []

    try:
        response = api.get(f'/orders/customer/{user_id_from_session}')
        if response.get('success'):
            orders = response.get('data', [])
        else:
            flash(response.get('message', 'Could not load order history.'), 'error')
    except APIError as e:
        flash(f"Error loading order history: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('user/orders.html', orders=orders)

@user_bp.route('/orders/<int:order_id>')
@login_required
def order_detail(order_id):
    """
    Displays the details of a specific order.
    """
    api = APIClient()
    order = None

    try:
        response = api.get(f'/orders/{order_id}/details')
        if response.get('success'):
            order = response.get('data')
            # The backend already checks if the order belongs to the user
            if not order:
                flash("Order not found or you don't have access.", 'warning')
                return redirect(url_for('user_bp.view_orders'))
        else:
            flash(response.get('message', 'Could not load order details.'), 'error')
            return redirect(url_for('user_bp.view_orders'))
    except APIError as e:
        flash(f"Error loading order details: {e.message}", 'error')
        return redirect(url_for('user_bp.view_orders'))
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
        return redirect(url_for('user_bp.view_orders'))

    return render_template('user/order_detail.html', order=order)
