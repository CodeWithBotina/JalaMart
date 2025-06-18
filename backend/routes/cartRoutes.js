// routes/cartRoutes.js
const express = require('express');
const router = express.Router();
const Cart = require('../models/Cart');

// Get cart items
router.get('/', async (req, res) => {
  try {
    // Get or create active cart
    let cartId = await Cart.getActiveCart(req.user.id_cliente);
    if (!cartId) {
      cartId = await Cart.createCart(req.user.id_cliente);
    }
    
    const items = await Cart.getCartItems(cartId);
    res.json({
      success: true,
      count: items.length,
      data: items
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Add item to cart
router.post('/', async (req, res) => {
  try {
    // Get or create active cart
    let cartId = await Cart.getActiveCart(req.user.id_cliente);
    if (!cartId) {
      cartId = await Cart.createCart(req.user.id_cliente);
    }
    
    const { id_producto, cantidad } = req.body;
    
    // Get product price
    const { rows } = await db.query(
      'SELECT precio, precio_descuento FROM comercial.producto WHERE id_producto = $1',
      [id_producto]
    );
    
    if (!rows[0]) {
      return res.status(404).json({ 
        success: false,
        message: 'Product not found' 
      });
    }
    
    const price = rows[0].precio_descuento || rows[0].precio;
    const items = await Cart.addItem(
      cartId, 
      id_producto, 
      cantidad || 1, 
      price
    );
    
    res.json({
      success: true,
      count: items.length,
      data: items
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Update item quantity
router.put('/:itemId', async (req, res) => {
  try {
    // Get active cart
    const cartId = await Cart.getActiveCart(req.user.id_cliente);
    if (!cartId) {
      return res.status(404).json({ 
        success: false,
        message: 'Cart not found' 
      });
    }
    
    const items = await Cart.updateItemQuantity(
      cartId, 
      req.params.itemId, 
      req.body.cantidad
    );
    
    res.json({
      success: true,
      count: items.length,
      data: items
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Remove item from cart
router.delete('/:itemId', async (req, res) => {
  try {
    // Get active cart
    const cartId = await Cart.getActiveCart(req.user.id_cliente);
    if (!cartId) {
      return res.status(404).json({ 
        success: false,
        message: 'Cart not found' 
      });
    }
    
    const items = await Cart.removeItem(cartId, req.params.itemId);
    res.json({
      success: true,
      count: items.length,
      data: items
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Checkout (convert cart to order)
router.post('/checkout', async (req, res) => {
  try {
    // Get active cart
    const cartId = await Cart.getActiveCart(req.user.id_cliente);
    if (!cartId) {
      return res.status(404).json({ 
        success: false,
        message: 'Cart not found' 
      });
    }
    
    // Get cart items
    const items = await Cart.getCartItems(cartId);
    if (items.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Cart is empty' 
      });
    }
    
    // Calculate subtotal and total
    const subtotal = items.reduce(
      (sum, item) => sum + (item.precio_unitario * item.cantidad), 
      0
    );
    const taxes = subtotal * 0.16; // Assuming 16% tax
    const total = subtotal + taxes;
    
    // Create order
    const order = await Order.create({
      id_cliente: req.user.id_cliente,
      direccion_envio: req.body.direccion_envio,
      metodo_pago: req.body.metodo_pago,
      subtotal,
      impuestos: taxes,
      total,
      items: items.map(item => ({
        id_producto: item.id_producto,
        cantidad: item.cantidad,
        precio_unitario: item.precio_unitario
      }))
    });
    
    // Deactivate cart
    await Cart.deactivateCart(cartId);
    
    res.status(201).json({
      success: true,
      data: order
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;