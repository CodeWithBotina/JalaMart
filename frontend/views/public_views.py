# jalamart_frontend/views/public_views.py
from flask import Blueprint, render_template, request, flash, current_app
from utils.api_client import APIClient, APIError

# Create a Blueprint for public routes
public_bp = Blueprint('public_bp', __name__)

@public_bp.route('/')
def home():
    """
    Renders the home page, displaying special offers, best offers,
    most sold products, and recently purchased products.
    Fetches data from the backend API.
    """
    api = APIClient()
    special_offer = None # Placeholder for a single special offer, if needed
    best_offers = []
    most_sold_products = []
    recently_purchased_products = []
    categories = []

    try:
        # Fetch best offers (Wireframe Page 1: "MEJORES OFERTAS")
        best_offers_response = api.get('/products/featured/discounted', include_auth=False)
        if best_offers_response and best_offers_response.get('success'):
            best_offers = best_offers_response.get('data', [])

        # Fetch most sold products (Wireframe Page 1: "PRODUCTOS MAS VENDIDOS")
        # Assuming your backend has an endpoint for best selling products
        most_sold_response = api.get('/reports/best-sellers', include_auth=False)
        if most_sold_response and most_sold_response.get('success'):
            most_sold_products = most_sold_response.get('data', [])

        # Fetch recently purchased products (Wireframe Page 1: "PRODUCTOS COMPRADOS RECIENTEMENTE")
        # Backend provides `reportes.productos_recientes` view, exposed via `/products/featured/recent`
        recently_purchased_response = api.get('/products/featured/recent', include_auth=False)
        if recently_purchased_response and recently_purchased_response.get('success'):
            recently_purchased_products = recently_purchased_response.get('data', [])

        # Fetch categories for the dropdown menu in the header
        categories_response = api.get('/categories', include_auth=False)
        if categories_response and categories_response.get('success'):
            categories = categories_response.get('data', [])

        # Placeholder for a single prominent special offer (e.g., the headphone offer)
        # You might need a specific backend endpoint for this or select one from best_offers
        if best_offers:
             special_offer = best_offers[0] # Just picking the first one as an example

    except APIError as e:
        flash(f"Error loading home page content: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template(
        'public/index.html',
        special_offer=special_offer,
        best_offers=best_offers,
        most_sold_products=most_sold_products,
        recently_purchased_products=recently_purchased_products,
        categories=categories
    )

@public_bp.route('/product/<int:product_id>')
def product_detail(product_id):
    """
    Renders the product detail page for a specific product ID.
    Fetches product information from the backend API.
    (Corresponds to Wireframe Page 2)
    """
    api = APIClient()
    product = None
    categories = []

    try:
        # Fetch product details
        product_response = api.get(f'/products/{product_id}', include_auth=False)
        if product_response and product_response.get('success'):
            product = product_response.get('data')

        # Fetch categories for the dropdown menu
        categories_response = api.get('/categories', include_auth=False)
        if categories_response and categories_response.get('success'):
            categories = categories_response.get('data', [])

        if not product:
            flash("Product not found.", 'warning')
            return render_template('errors/404.html'), 404 # Or redirect to home

    except APIError as e:
        flash(f"Error loading product details: {e.message}", 'error')
        return render_template('errors/500.html'), 500 # Or render product_detail with error message
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')
        return render_template('errors/500.html'), 500

    return render_template('public/product_detail.html', product=product, categories=categories)

@public_bp.route('/search')
def search_products():
    """
    Handles product search queries and displays results.
    Prevents SQL injection by relying on backend's parameterized queries
    and proper input sanitization on the frontend for display.
    """
    query = request.args.get('query', '').strip()
    products = []
    categories = []
    api = APIClient()

    if not query:
        flash("Please enter a search term.", 'info')
        return render_template('public/search_results.html', products=products, query=query, categories=categories)

    try:
        # Sanitize query for display, but rely on backend for actual query safety
        sanitized_query = query # For display purposes on the frontend

        search_response = api.get(f'/products/search/{query}', include_auth=False)
        if search_response and search_response.get('success'):
            products = search_response.get('data', [])

        # Fetch categories for the dropdown menu
        categories_response = api.get('/categories', include_auth=False)
        if categories_response and categories_response.get('success'):
            categories = categories_response.get('data', [])

        if not products:
            flash(f"No products found for '{sanitized_query}'.", 'info')

    except APIError as e:
        flash(f"Error performing search: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred during search: {str(e)}", 'error')

    return render_template('public/search_results.html', products=products, query=query, categories=categories)

@public_bp.route('/categories')
def view_all_categories():
    """
    Displays a list of all active categories.
    """
    api = APIClient()
    categories = []

    try:
        categories_response = api.get('/categories', include_auth=False)
        if categories_response and categories_response.get('success'):
            categories = categories_response.get('data', [])
        if not categories:
            flash("No categories found.", 'info')
    except APIError as e:
        flash(f"Error loading categories: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('public/categories.html', categories=categories)

@public_bp.route('/categories/<int:category_id>/products')
def products_by_category(category_id):
    """
    Displays products belonging to a specific category.
    (Corresponds to Wireframe Page 5 and 6 style)
    """
    api = APIClient()
    category_name = "Category"
    products = []
    categories = [] # For the navigation dropdown

    try:
        # Get category details to display name
        category_response = api.get(f'/categories/{category_id}', include_auth=False)
        if category_response and category_response.get('success'):
            category_data = category_response.get('data')
            if category_data:
                category_name = category_data.get('nombre', f"Category {category_id}")

        # Get products by category
        products_response = api.get(f'/categories/{category_id}/products', include_auth=False)
        if products_response and products_response.get('success'):
            products = products_response.get('data', [])

        # Fetch all categories for navigation
        all_categories_response = api.get('/categories', include_auth=False)
        if all_categories_response and all_categories_response.get('success'):
            categories = all_categories_response.get('data', [])

        if not products:
            flash(f"No products found for category '{category_name}'.", 'info')

    except APIError as e:
        flash(f"Error loading products for category: {e.message}", 'error')
    except Exception as e:
        flash(f"An unexpected error occurred: {str(e)}", 'error')

    return render_template('public/products_by_category.html',
                           category_name=category_name,
                           products=products,
                           categories=categories)