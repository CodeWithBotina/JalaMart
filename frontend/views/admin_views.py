# jalamart_frontend/views/admin_views.py
from flask import Blueprint, render_template, redirect, url_for, flash, request
from utils.api_client import APIClient, APIError
from utils.decorators import admin_required
from utils.forms import ProductForm, CategoryForm # Assuming you'll need forms for user/order management too

# Create a Blueprint for admin routes
admin_bp = Blueprint('admin_bp', __name__)

@admin_bp.route('/')
@admin_required
def admin_dashboard():
    """
    Renders the admin dashboard.
    Displays an overview of key reports.
    """
    api = APIClient()
    best_selling_products = []
    most_active_customers = []
    sales_by_category = []

    try:
        # Fetch data for admin overview
        best_sellers_response = api.get('/reports/best-sellers')
        if best_sellers_response and best_sellers_response.get('success'):
            best_selling_products = best_sellers_response.get('data', [])

        active_customers_response = api.get('/reports/active-customers')
        if active_customers_response and active_customers_response.get('success'):
            most_active_customers = active_customers_response.get('data', [])

        sales_category_response = api.get('/reports/sales-by-category') # Assuming this endpoint exists or can be created
        if sales_category_response and sales_category_response.get('success'):
            sales_by_category = sales_category_response.get('data', [])

    except APIError as e:
        flash(f"Error loading admin dashboard data: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/dashboard.html',
                           best_selling_products=best_selling_products,
                           most_active_customers=most_active_customers,
                           sales_by_category=sales_by_category)


@admin_bp.route('/products')
@admin_required
def manage_products():
    """
    Renders the product management page for admins.
    Displays all products with edit/delete options.
    (Corresponds to Wireframe Page 4)
    """
    api = APIClient()
    products = []
    categories = [] # For filtering or product forms

    try:
        # Fetch all products (admin gets all, not just active)
        products_response = api.get('/products') # Backend /products endpoint for all products
        if products_response and products_response.get('success'):
            products = products_response.get('data', [])

        # Fetch categories to populate dropdowns in create/edit product forms
        categories_response = api.get('/categories')
        if categories_response and categories_response.get('success'):
            categories = categories_response.get('data', [])

    except APIError as e:
        flash(f"Error loading products for management: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/products.html', products=products, categories=categories)


@admin_bp.route('/products/add', methods=['GET', 'POST'])
@admin_required
def add_product():
    """
    Handles adding a new product.
    """
    form = ProductForm()
    api = APIClient()
    categories_for_form = [] # For SelectField choices

    try:
        categories_response = api.get('/categories')
        if categories_response and categories_response.get('success'):
            # Assuming categories come with 'id_categoria' and 'nombre'
            categories_for_form = [(c['id_categoria'], c['nombre']) for c in categories_response['data']]
        form.id_categoria.choices = categories_for_form # Set choices for category dropdown
    except APIError as e:
        flash(f"Error loading categories for product form: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')


    if form.validate_on_submit():
        product_data = {
            'nombre': form.nombre.data,
            'descripcion': form.descripcion.data,
            'precio': str(form.precio.data), # Convert Decimal to string for JSON
            'precio_descuento': str(form.precio_descuento.data) if form.precio_descuento.data else None,
            'id_categoria': form.id_categoria.data,
            'id_proveedor': form.id_proveedor.data,
            'stock': form.stock.data,
            'sku': form.sku.data,
            'imagen_url': form.imagen_url.data,
            'activo': form.activo.data
        }
        try:
            response = api.post('/products', product_data)
            if response.get('success'):
                flash('Product added successfully!', 'success')
                return redirect(url_for('admin_bp.manage_products'))
            else:
                flash(response.get('message', 'Failed to add product.'), 'error')
        except APIError as e:
            flash(f"Failed to add product: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/product_form.html', form=form, title='Add New Product', is_edit=False)


@admin_bp.route('/products/edit/<int:product_id>', methods=['GET', 'POST'])
@admin_required
def edit_product(product_id):
    """
    Handles editing an existing product.
    (Corresponds to Wireframe Page 3)
    """
    api = APIClient()
    product = None
    categories_for_form = []

    try:
        # Fetch existing product data
        product_response = api.get(f'/products/{product_id}')
        if product_response and product_response.get('success'):
            product = product_response.get('data')
        else:
            flash(product_response.get('message', 'Product not found for editing.'), 'error')
            return redirect(url_for('admin_bp.manage_products'))

        # Fetch categories for SelectField choices
        categories_response = api.get('/categories')
        if categories_response and categories_response.get('success'):
            categories_for_form = [(c['id_categoria'], c['nombre']) for c in categories_response['data']]

    except APIError as e:
        flash(f"Error loading product for editing: {e.message}", 'error')
        return redirect(url_for('admin_bp.manage_products'))
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    # Populate form with product data
    form = ProductForm(obj=product)
    form.id_categoria.choices = categories_for_form

    if form.validate_on_submit():
        updated_data = {
            'nombre': form.nombre.data,
            'descripcion': form.descripcion.data,
            'precio': str(form.precio.data),
            'precio_descuento': str(form.precio_descuento.data) if form.precio_descuento.data else None,
            'id_categoria': form.id_categoria.data,
            'id_proveedor': form.id_proveedor.data,
            'stock': form.stock.data,
            'sku': form.sku.data,
            'imagen_url': form.imagen_url.data,
            'activo': form.activo.data
        }
        try:
            response = api.put(f'/products/{product_id}', updated_data)
            if response.get('success'):
                flash('Product updated successfully!', 'success')
                return redirect(url_for('admin_bp.manage_products'))
            else:
                flash(response.get('message', 'Failed to update product.'), 'error')
        except APIError as e:
            flash(f"Failed to update product: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/product_form.html', form=form, title=f'Edit Product: {product.get("nombre", "")}', is_edit=True, product_id=product_id)

@admin_bp.route('/products/delete/<int:product_id>', methods=['POST'])
@admin_required
def delete_product(product_id):
    """
    Handles deleting a product (marks as inactive in backend).
    """
    api = APIClient()
    try:
        # Backend's delete endpoint marks product as inactive
        response = api.delete(f'/products/{product_id}')
        if response.get('success'):
            flash('Product deactivated successfully!', 'success')
        else:
            flash(response.get('message', 'Failed to deactivate product.'), 'error')
    except APIError as e:
        flash(f"Failed to deactivate product: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return redirect(url_for('admin_bp.manage_products'))


@admin_bp.route('/categories')
@admin_required
def manage_categories():
    """
    Renders the category management page for admins.
    """
    api = APIClient()
    categories = []
    try:
        response = api.get('/categories') # Admin can see all, not just active
        if response.get('success'):
            categories = response.get('data', [])
        else:
            flash(response.get('message', 'Could not load categories.'), 'error')
    except APIError as e:
        flash(f"Error loading categories for management: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/categories.html', categories=categories)


@admin_bp.route('/categories/add', methods=['GET', 'POST'])
@admin_required
def add_category():
    """
    Handles adding a new category.
    """
    form = CategoryForm()
    if form.validate_on_submit():
        api = APIClient()
        category_data = {
            'nombre': form.nombre.data,
            'descripcion': form.descripcion.data,
            'slug': form.slug.data,
            'imagen_url': form.imagen_url.data,
            'activa': form.activa.data
        }
        try:
            response = api.post('/categories', category_data)
            if response.get('success'):
                flash('Category added successfully!', 'success')
                return redirect(url_for('admin_bp.manage_categories'))
            else:
                flash(response.get('message', 'Failed to add category.'), 'error')
        except APIError as e:
            flash(f"Failed to add category: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')
    return render_template('admin/category_form.html', form=form, title='Add New Category', is_edit=False)


@admin_bp.route('/categories/edit/<int:category_id>', methods=['GET', 'POST'])
@admin_required
def edit_category(category_id):
    """
    Handles editing an existing category.
    """
    api = APIClient()
    category = None

    try:
        category_response = api.get(f'/categories/{category_id}')
        if category_response and category_response.get('success'):
            category = category_response.get('data')
        else:
            flash(category_response.get('message', 'Category not found for editing.'), 'error')
            return redirect(url_for('admin_bp.manage_categories'))
    except APIError as e:
        flash(f"Error loading category for editing: {e.message}", 'error')
        return redirect(url_for('admin_bp.manage_categories'))
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    form = CategoryForm(obj=category)

    if form.validate_on_submit():
        updated_data = {
            'nombre': form.nombre.data,
            'descripcion': form.descripcion.data,
            'slug': form.slug.data,
            'imagen_url': form.imagen_url.data,
            'activa': form.activa.data
        }
        try:
            response = api.put(f'/categories/{category_id}', updated_data)
            if response.get('success'):
                flash('Category updated successfully!', 'success')
                return redirect(url_for('admin_bp.manage_categories'))
            else:
                flash(response.get('message', 'Failed to update category.'), 'error')
        except APIError as e:
            flash(f"Failed to update category: {e.message}", 'error')
        except Exception as e:
            flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('admin/category_form.html', form=form, title=f'Edit Category: {category.get("nombre", "")}', is_edit=True, category_id=category_id)


@admin_bp.route('/categories/delete/<int:category_id>', methods=['POST'])
@admin_required
def delete_category(category_id):
    """
    Handles deleting a category (marks as inactive in backend).
    """
    api = APIClient()
    try:
        response = api.delete(f'/categories/{category_id}')
        if response.get('success'):
            flash('Category deactivated successfully!', 'success')
        else:
            flash(response.get('message', 'Failed to deactivate category.'), 'error')
    except APIError as e:
        flash(f"Failed to deactivate category: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
    return redirect(url_for('admin_bp.manage_categories'))


@admin_bp.route('/customers')
@admin_required
def manage_customers():
    """
    Renders the customer management page for admins.
    NOTE: Backend currently doesn't have a GET all customers endpoint for admin.
    This would need to be added to the backend (e.g., in customerRoutes, accessible by admin middleware).
    For now, this will display a placeholder or limited info.
    """
    flash("Customer management endpoint is not fully implemented in the backend.", 'info')
    customers = [] # Would fetch from backend /customers (admin only)
    return render_template('admin/customers.html', customers=customers)


@admin_bp.route('/orders')
@admin_required
def manage_orders():
    """
    Renders the order management page for admins.
    NOTE: Backend currently doesn't have a GET all orders endpoint for admin.
    This would need to be added to the backend (e.g., in orderRoutes, accessible by admin middleware).
    """
    flash("Admin order management endpoint is not fully implemented in the backend.", 'info')
    orders = [] # Would fetch from backend /orders (admin only)
    return render_template('admin/orders.html', orders=orders)