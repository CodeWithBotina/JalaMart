// middlewares/auth.js
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false,
        message: 'No token provided, authorization denied' 
      });
    }
    
    const token = authHeader.replace('Bearer ', '');
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user still exists
    const { rows } = await db.query(
      `SELECT u.*, c.id_cliente 
       FROM seguridad.usuario u
       LEFT JOIN comercial.cliente c ON u.id_cliente = c.id_cliente
       WHERE u.id_usuario = $1`, 
      [decoded.id]
    );
    
    if (!rows[0] || !rows[0].activo) {
      return res.status(401).json({ 
        success: false,
        message: 'User not found or inactive' 
      });
    }
    
    // Add user to request
    req.user = {
      id: decoded.id,
      role: decoded.role,
      id_cliente: rows[0].id_cliente,
      email: rows[0].email
    };
    
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false,
        message: 'Token expired',
        expiredAt: err.expiredAt 
      });
    }
    
    res.status(401).json({ 
      success: false,
      message: 'Invalid token',
      error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  }
};

module.exports = authenticate;