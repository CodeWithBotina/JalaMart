# jalamart_frontend/utils/decorators.py
from functools import wraps
from flask import session, flash, redirect, url_for, request

def login_required(f):
    """
    Decorator that redirects unauthenticated users to the login page.
    Flashes a message indicating that login is required.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session:
            flash('You need to be logged in to access this page.', 'warning')
            return redirect(url_for('auth_bp.login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """
    Decorator that checks if the logged-in user has 'admin' role.
    Redirects non-admin users with a forbidden message.
    Requires @login_required to be applied first.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session or session['user'].get('role') != 'admin':
            flash('Access forbidden: Admin privileges required.', 'danger')
            return redirect(url_for('public_bp.home')) # Redirect to home or a suitable unauthorized page
        return f(*args, **kwargs)
    return decorated_function
