from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, IntegerField, TextAreaField, DecimalField, BooleanField
from wtforms.validators import DataRequired, Email, Length, EqualTo, NumberRange, Optional, URL, Regexp

class LoginForm(FlaskForm):
    """Form for user login."""
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')

class RegistrationForm(FlaskForm):
    """Form for new customer registration."""
    nombre = StringField('First Name', validators=[DataRequired(), Length(min=2, max=100)])
    apellido = StringField('Last Name', validators=[DataRequired(), Length(min=2, max=100)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=8, message='Password must be at least 8 characters long.')])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password', message='Passwords must match.')])
    direccion = TextAreaField('Address', validators=[DataRequired(), Length(max=255)])
    telefono = StringField('Phone', validators=[DataRequired(), Regexp(r'^\+?[\d\s\-\(\)]{7,20}$', message='Invalid phone number format.')])
    submit = SubmitField('Create Account')

class ProfileUpdateForm(FlaskForm):
    """Form for updating customer profile information."""
    nombre = StringField('First Name', validators=[DataRequired(), Length(min=2, max=100)])
    apellido = StringField('Last Name', validators=[DataRequired(), Length(min=2, max=100)])
    telefono = StringField('Phone', validators=[DataRequired(), Regexp(r'^\+?[\d\s\-\(\)]{7,20}$', message='Invalid phone number format.')])
    direccion = TextAreaField('Address', validators=[DataRequired(), Length(max=255)])
    receive_notifications = BooleanField('I want to receive offer notifications') # Not directly mapped to DB but good for UI
    submit = SubmitField('Update Profile')

class ChangePasswordForm(FlaskForm):
    """Form for changing user password."""
    current_password = PasswordField('Current Password', validators=[DataRequired()])
    new_password = PasswordField('New Password', validators=[DataRequired(), Length(min=8, message='New password must be at least 8 characters long.')])
    confirm_new_password = PasswordField('Confirm New Password', validators=[DataRequired(), EqualTo('new_password', message='Passwords must match.')])
    submit = SubmitField('Change Password')

class ProductForm(FlaskForm):
    """Form for creating and updating products (Admin)."""
    nombre = StringField('Product Name', validators=[DataRequired(), Length(max=100)])
    descripcion = TextAreaField('Description', validators=[DataRequired()])
    precio = DecimalField('Price', validators=[DataRequired(), NumberRange(min=0.01)], places=2)
    precio_descuento = DecimalField('Discount Price', validators=[Optional(), NumberRange(min=0.01)], places=2)
    id_categoria = IntegerField('Category ID', validators=[DataRequired(), NumberRange(min=1)]) # Could be a SelectField with dynamic choices
    id_proveedor = IntegerField('Supplier ID', validators=[DataRequired(), NumberRange(min=1)]) # Could be a SelectField
    stock = IntegerField('Stock', validators=[DataRequired(), NumberRange(min=0)])
    sku = StringField('SKU', validators=[DataRequired(), Length(max=50)])
    imagen_url = StringField('Image URL', validators=[Optional(), URL()])
    activo = BooleanField('Active')
    submit = SubmitField('Save Product')

class CategoryForm(FlaskForm):
    """Form for creating and updating categories (Admin)."""
    nombre = StringField('Category Name', validators=[DataRequired(), Length(max=100)])
    descripcion = TextAreaField('Description', validators=[Optional()])
    slug = StringField('Slug', validators=[DataRequired(), Length(max=100), Regexp(r'^[a-z0-9-]+$', message='Slug must be lowercase alphanumeric with hyphens.')])
    imagen_url = StringField('Image URL', validators=[Optional(), URL()])
    activa = BooleanField('Active')
    submit = SubmitField('Save Category')

class AddToCartForm(FlaskForm):
    """Simple form for adding a product to cart."""
    product_id = IntegerField('Product ID', validators=[DataRequired(), NumberRange(min=1)])
    quantity = IntegerField('Quantity', validators=[DataRequired(), NumberRange(min=1)])
    submit = SubmitField('Add to Cart')

class UpdateCartItemForm(FlaskForm):
    """Form for updating quantity of a cart item."""
    quantity = IntegerField('Quantity', validators=[DataRequired(), NumberRange(min=0)]) # Quantity 0 means remove
    submit = SubmitField('Update Quantity')