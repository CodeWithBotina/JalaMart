// jalamart_frontend/static/js/main.js
document.addEventListener('DOMContentLoaded', function() {
    // Example: Dynamically load categories into the dropdown (this would typically come from an API)
    // For now, these are static in base.html. If you have a separate API endpoint for categories
    // uncomment and modify the fetch logic below.
    /*
    const categoriesDropdown = document.querySelector('.group .absolute');
    if (categoriesDropdown) {
        fetch('/api/categories') // Assuming an endpoint to get categories
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Clear existing static categories (except 'View All')
                    while (categoriesDropdown.firstChild && categoriesDropdown.firstChild.tagName !== 'HR') {
                        categoriesDropdown.removeChild(categoriesDropdown.firstChild);
                    }
                    data.data.forEach(category => {
                        const link = document.createElement('a');
                        link.href = `/categories/${category.id_categoria}/products`; // Or category.slug
                        link.classList.add('block', 'px-4', 'py-2', 'hover:bg-gray-100');
                        link.textContent = category.nombre;
                        categoriesDropdown.insertBefore(link, categoriesDropdown.firstChild);
                    });
                }
            })
            .catch(error => console.error('Error fetching categories:', error));
    }
    */

    // Simple script to handle current year in footer
    const currentYearSpan = document.getElementById('current-year');
    if (currentYearSpan) {
        currentYearSpan.textContent = new Date().getFullYear();
    }
});