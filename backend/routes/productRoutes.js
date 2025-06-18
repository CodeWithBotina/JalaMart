// routes/productRoutes.js
const express = require('express');
const router = express.Router();
const Product = require('../models/Product');

// Get all products
router.get('/', async (req, res) => {
  try {
    const products = await Product.getAll();
    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get product by ID
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.getById(req.params.id);
    if (!product) {
      return res.status(404).json({ 
        success: false,
        message: 'Product not found' 
      });
    }
    res.json({
      success: true,
      data: product
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Search products
router.get('/search/:query', async (req, res) => {
  try {
    const products = await Product.search(req.params.query);
    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get featured products
router.get('/featured/recent', async (req, res) => {
  try {
    const products = await Product.getFeatured();
    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get discounted products
router.get('/featured/discounted', async (req, res) => {
  try {
    const products = await Product.getDiscounted();
    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Create product (admin only)
router.post('/', async (req, res) => {
  try {
    const newProduct = await Product.create(req.body);
    res.status(201).json({
      success: true,
      data: newProduct
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Update product (admin only)
router.put('/:id', async (req, res) => {
  try {
    const updatedProduct = await Product.update(req.params.id, req.body);
    if (!updatedProduct) {
      return res.status(404).json({ 
        success: false,
        message: 'Product not found' 
      });
    }
    res.json({
      success: true,
      data: updatedProduct
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Delete product (admin only)
router.delete('/:id', async (req, res) => {
  try {
    const deletedProduct = await Product.delete(req.params.id);
    if (!deletedProduct) {
      return res.status(404).json({ 
        success: false,
        message: 'Product not found' 
      });
    }
    res.json({
      success: true,
      data: deletedProduct
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;