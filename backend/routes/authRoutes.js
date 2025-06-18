// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Customer = require('../models/Customer');
const User = require('../models/User');
require('dotenv').config();

// Register new customer
router.post('/register', async (req, res) => {
  try {
    // Check if email already exists
    const existingCustomer = await Customer.getByEmail(req.body.email);
    if (existingCustomer) {
      return res.status(400).json({ 
        success: false,
        message: 'Email already registered' 
      });
    }
    
    const newCustomer = await Customer.create(req.body);
    
    // Don't return password
    delete newCustomer.password;
    
    res.status(201).json({
      success: true,
      data: newCustomer
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user by email
    const user = await User.getByEmail(email);
    if (!user) {
      return res.status(401).json({ 
        success: false,
        message: 'Invalid credentials' 
      });
    }
    
    // Check password
    const isMatch = await User.comparePassword(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ 
        success: false,
        message: 'Invalid credentials' 
      });
    }
    
    // Update last login
    await User.updateLastLogin(user.id_usuario);
    
    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id_usuario, 
        role: user.rol,
        id_cliente: user.id_cliente 
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({
      success: true,
      token,
      user: {
        id: user.id_usuario,
        email: user.email,
        role: user.rol,
        id_cliente: user.id_cliente
      }
    });
  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
});

// Refresh token (would need implementation)
router.post('/refresh', (req, res) => {
  // Implementation for token refresh
});

module.exports = router;