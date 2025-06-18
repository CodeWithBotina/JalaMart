// backend/app.js
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const productRoutes = require('./routes/productRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const orderRoutes = require('./routes/orderRoutes');
const customerRoutes = require('./routes/customerRoutes');
const authRoutes = require('./routes/authRoutes');
const cartRoutes = require('./routes/cartRoutes');
const reportRoutes = require('./routes/reportRoutes');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());
app.use(bodyParser.json({ limit: '10kb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10kb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Public routes - These routes do NOT require authentication
app.use('/api/auth', authRoutes);
// Products and categories need to be public for unauthenticated browsing
app.use('/api/products', productRoutes); // <-- Moved here to be public
app.use('/api/categories', categoryRoutes); // <-- Moved here to be public


// Protected routes - These routes DO require authentication
const auth = require('./middlewares/auth');
const admin = require('./middlewares/admin');

// All routes below this point will require the 'auth' middleware
app.use('/api/orders', auth, orderRoutes);
app.use('/api/customers', auth, customerRoutes); // Note: Admin-specific customer routes will still need 'admin' middleware within customerRoutes if not applied globally here
app.use('/api/cart', auth, cartRoutes);
// Reports should generally be admin-only
app.use('/api/reports', auth, admin, reportRoutes); // Added 'auth' for consistency before 'admin'

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Error handling middleware (should be last)
app.use((err, req, res, next) => {
  console.error(err.stack); // Log the stack trace for debugging

  // Handle specific known errors
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: err.errors // Pass specific validation errors if available
    });
  }

  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Authentication error: Invalid token'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Authentication error: Token expired',
      expiredAt: err.expiredAt
    });
  }

  // Generic internal server error
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    // In production, avoid exposing sensitive error details
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});