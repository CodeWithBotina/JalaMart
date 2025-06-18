// routes/orderRoutes.js
const express = require('express');
const router = express.Router();
const Order = require('../models/Order');

// Get customer orders
router.get('/customer/:id', async (req, res) => {
  try {
    // Verify customer can only access their own orders
    if (req.user.id_cliente !== parseInt(req.params.id)) {
      return res.status(403).json({ 
        success: false,
        message: 'Unauthorized' 
      });
    }
    
    const orders = await Order.getByCustomer(req.params.id);
    res.json({
      success: true,
      count: orders.length,
      data: orders
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Create new order
router.post('/', async (req, res) => {
  try {
    const newOrder = await Order.create({
      ...req.body,
      id_cliente: req.user.id_cliente
    });
    
    res.status(201).json({
      success: true,
      data: newOrder
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get order details
router.get('/:id/details', async (req, res) => {
  try {
    const order = await Order.getById(req.params.id);
    
    // Verify customer can only access their own order
    if (order.id_cliente !== req.user.id_cliente) {
      return res.status(403).json({ 
        success: false,
        message: 'Unauthorized' 
      });
    }
    
    const items = await Order.getItems(req.params.id);
    res.json({
      success: true,
      data: {
        ...order,
        items
      }
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Update order status (admin only)
router.put('/:id/status', async (req, res) => {
  try {
    const updatedOrder = await Order.updateStatus(
      req.params.id, 
      req.body.status
    );
    
    res.json({
      success: true,
      data: updatedOrder
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;