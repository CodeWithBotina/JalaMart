// routes/categoryRoutes.js
const express = require('express');
const router = express.Router();
const Category = require('../models/Category');

// Get all categories
router.get('/', async (req, res) => {
  try {
    const categories = await Category.getAll();
    res.json({
      success: true,
      count: categories.length,
      data: categories
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get category by ID
router.get('/:id', async (req, res) => {
  try {
    const category = await Category.getById(req.params.id);
    if (!category) {
      return res.status(404).json({ 
        success: false,
        message: 'Category not found' 
      });
    }
    res.json({
      success: true,
      data: category
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Get products by category
router.get('/:id/products', async (req, res) => {
  try {
    const products = await Category.getProducts(req.params.id);
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

// Create category (admin only)
router.post('/', async (req, res) => {
  try {
    const newCategory = await Category.create(req.body);
    res.status(201).json({
      success: true,
      data: newCategory
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Update category (admin only)
router.put('/:id', async (req, res) => {
  try {
    const updatedCategory = await Category.update(req.params.id, req.body);
    if (!updatedCategory) {
      return res.status(404).json({ 
        success: false,
        message: 'Category not found' 
      });
    }
    res.json({
      success: true,
      data: updatedCategory
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Delete category (admin only)
router.delete('/:id', async (req, res) => {
  try {
    const deletedCategory = await Category.delete(req.params.id);
    if (!deletedCategory) {
      return res.status(404).json({ 
        success: false,
        message: 'Category not found' 
      });
    }
    res.json({
      success: true,
      data: deletedCategory
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;