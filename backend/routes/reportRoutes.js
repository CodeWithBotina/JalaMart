// routes/reportRoutes.js
const express = require('express');
const router = express.Router();
const Report = require('../models/Report');

// Get best selling products
router.get('/best-sellers', async (req, res) => {
  try {
    const products = await Report.getProductosMasVendidos();
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

// Get best offers
router.get('/best-offers', async (req, res) => {
  try {
    const products = await Report.getMejoresOfertas();
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

// Get active customers
router.get('/active-customers', async (req, res) => {
  try {
    const customers = await Report.getClientesActivos();
    res.json({
      success: true,
      count: customers.length,
      data: customers
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;