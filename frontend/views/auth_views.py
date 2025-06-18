# jalamart_frontend/views/auth_views.py
from flask import Blueprint, render_template, redirect, url_for, flash, session, request
from utils.forms import LoginForm, RegistrationForm
from utils.api_client import APIClient, APIError

# Create a Blueprint for authentication routes
auth_bp = Blueprint('auth_bp', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """
    Handles user login.
    (Corresponds to Wireframe Page 10)
    """
    if 'user' in session: # If already logged in, redirect to user dashboard
        return redirect(url_for('user_bp.user_dashboard'))

    form = LoginForm()
    if form.validate_on_submit():
        api = APIClient()
        email = form.email.data
        password = form.password.data

        try:
            response = api.post('/auth/login', {'email': email, 'password': password}, include_auth=False)
            if response.get('success'):
                user_data = response.get('user')
                token = response.get('token')

                session['token'] = token
                session['user'] = user_data # Store user data in session (id, email, role, id_cliente)
                session['cart_item_count'] = 0 # Initialize cart count on login

                flash('Login successful!', 'success')

                # Redirect to 'next' URL if provided, otherwise to user dashboard
                next_page = request.args.get('next')
                return redirect(next_page or url_for('user_bp.user_dashboard'))
            else:
                flash(response.get('message', 'Invalid credentials. Please try again.'), 'error')
        except APIError as e:
            flash(f"Login failed: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('auth/login.html', form=form)

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    """
    Handles new customer registration.
    (Corresponds to Wireframe Page 9)
    """
    if 'user' in session: # If already logged in, redirect to user dashboard
        return redirect(url_for('user_bp.user_dashboard'))

    form = RegistrationForm()
    if form.validate_on_submit():
        api = APIClient()
        customer_data = {
            'nombre': form.nombre.data,
            'apellido': form.apellido.data,
            'email': form.email.data,
            'password': form.password.data,
            'direccion': form.direccion.data,
            'telefono': form.telefono.data
        }
        try:
            response = api.post('/auth/register', customer_data, include_auth=False)
            if response.get('success'):
                flash('Registration successful! Please login.', 'success')
                return redirect(url_for('auth_bp.login'))
            else:
                flash(response.get('message', 'Registration failed. Please try again.'), 'error')
        except APIError as e:
            flash(f"Registration failed: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('auth/register.html', form=form)

@auth_bp.route('/logout')
def logout():
    """
    Logs out the user by clearing the session.
    """
    session.pop('token', None)
    session.pop('user', None)
    session.pop('cart_item_count', 0)
    flash('You have been logged out.', 'info')
    return redirect(url_for('public_bp.home'))
