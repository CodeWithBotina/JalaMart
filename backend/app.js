// app.js
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

// Public routes
app.use('/api/auth', authRoutes);

// Protected routes
const auth = require('./middlewares/auth');
const admin = require('./middlewares/admin');
app.use('/api/products', auth, productRoutes);
app.use('/api/categories', auth, categoryRoutes);
app.use('/api/orders', auth, orderRoutes);
app.use('/api/customers', auth, customerRoutes);
app.use('/api/cart', auth, cartRoutes);
app.use('/api/reports', admin, reportRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: err.errors
    });
  }
  
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Authentication error'
    });
  }
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});