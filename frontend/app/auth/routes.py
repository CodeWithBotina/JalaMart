# app/auth/routes.py
from flask import render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, current_user
from app.auth import bp
from app.auth.forms import LoginForm, RegistrationForm
import requests
from config import Config

@bp.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('main.index'))
    form = LoginForm()
    if form.validate_on_submit():
        response = requests.post(
            f"{Config.BACKEND_URL}/api/auth/login",
            json={
                'email': form.email.data,
                'password': form.password.data
            }
        )
        if response.status_code == 200:
            data = response.json()
            # Here you would typically create a user object and login
            # For simplicity, we'll just redirect
            return redirect(url_for('main.index'))
        flash('Invalid email or password', 'danger')
    return render_template('auth/login.html', title='Sign In', form=form)

@bp.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('main.index'))
    form = RegistrationForm()
    if form.validate_on_submit():
        response = requests.post(
            f"{Config.BACKEND_URL}/api/auth/register",
            json={
                'nombre': form.name.data,
                'apellido': form.lastname.data,
                'email': form.email.data,
                'password': form.password.data,
                'direccion': form.address.data,
                'telefono': form.phone.data
            }
        )
        if response.status_code == 201:
            flash('Congratulations, you are now a registered user!', 'success')
            return redirect(url_for('auth.login'))
        flash('Registration failed. Please try again.', 'danger')
    return render_template('auth/register.html', title='Register', form=form)

@bp.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('main.index'))