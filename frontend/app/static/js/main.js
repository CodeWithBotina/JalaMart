// app/static/js/main.js
document.addEventListener('DOMContentLoaded', function() {
    // Cart quantity adjustments
    document.querySelectorAll('.quantity-adjust').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const input = this.parentElement.querySelector('.quantity-input');
            let quantity = parseInt(input.value);
            
            if (this.classList.contains('quantity-up')) {
                quantity += 1;
            } else if (this.classList.contains('quantity-down') && quantity > 1) {
                quantity -= 1;
            }
            
            input.value = quantity;
        });
    });

    // Search functionality
    const searchForm = document.getElementById('search-form');
    if (searchForm) {
        searchForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const query = this.querySelector('input[name="q"]').value.trim();
            if (query) {
                window.location.href = `/products/search?q=${encodeURIComponent(query)}`;
            }
        });
    }

    // Flash message auto-dismiss
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.opacity = '0';
            setTimeout(() => alert.remove(), 300);
        }, 5000);
    });
});