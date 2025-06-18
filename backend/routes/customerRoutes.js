// routes/customerRoutes.js
const express = require('express');
const router = express.Router();
const Customer = require('../models/Customer');

// Get customer profile
router.get('/:id', async (req, res) => {
  try {
    // Verify customer can only access their own profile
    if (req.user.id_cliente !== parseInt(req.params.id)) {
      return res.status(403).json({ 
        success: false,
        message: 'Unauthorized' 
      });
    }
    
    const customer = await Customer.getById(req.params.id);
    if (!customer) {
      return res.status(404).json({ 
        success: false,
        message: 'Customer not found' 
      });
    }
    
    res.json({
      success: true,
      data: customer
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Update customer profile
router.put('/:id', async (req, res) => {
  try {
    // Verify customer can only update their own profile
    if (req.user.id_cliente !== parseInt(req.params.id)) {
      return res.status(403).json({ 
        success: false,
        message: 'Unauthorized' 
      });
    }
    
    const updatedCustomer = await Customer.update(req.params.id, req.body);
    
    res.json({
      success: true,
      data: updatedCustomer
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Change password
router.put('/:id/password', async (req, res) => {
  try {
    // Verify customer can only change their own password
    if (req.user.id_cliente !== parseInt(req.params.id)) {
      return res.status(403).json({ 
        success: false,
        message: 'Unauthorized' 
      });
    }
    
    const { currentPassword, newPassword } = req.body;
    await Customer.updatePassword(
      req.params.id, 
      currentPassword, 
      newPassword
    );
    
    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

module.exports = router;