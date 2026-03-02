const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { sequelize } = require('./config/database');
const { initializeFirebase, getFirebaseInstance } = require('./config/firebase');
const { initializeFirebaseStorage, isGCSAvailable, uploadToGCS, deleteFromGCS } = require('./services/googleCloudStorage');
const errorHandler = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const businessRoutes = require('./routes/businesses');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const adminRoutes = require('./routes/admin');
const uploadRoutes = require('./routes/upload');
const unitRoutes = require('./routes/units');
const musicRoutes = require('./routes/music');
const mediaRoutes = require('./routes/media');

const app = express();
// Use PORT from env (Coolify/platforms) or fallback to 8000
const PORT = parseInt(process.env.PORT || '8000', 10);

// Security middleware
app.use(helmet());
app.use(compression());

// Rate limiting (disabled by default in development)
const enableRateLimit = (process.env.RATE_LIMIT_ENABLED ?? (process.env.NODE_ENV === 'production' ? 'true' : 'false')) === 'true';
if (enableRateLimit) {
  const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000'), // default 1 minute
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '1000'), // higher default for local testing
    message: 'Too many requests from this IP, please try again later.'
  });
  app.use('/api/', limiter);
}

// CORS configuration (supports multiple origins via CORS_ORIGINS or fallback to CORS_ORIGIN)
const rawCorsOrigins = process.env.CORS_ORIGINS || process.env.CORS_ORIGIN || 'http://localhost:3000';
const allowedOrigins = rawCorsOrigins
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    console.warn(`CORS blocked request from origin: ${origin}`);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true
};

// Ensure preflight requests are handled globally
app.options('*', cors(corsOptions));

app.use((req, res, next) => {
  cors(corsOptions)(req, res, (err) => {
    if (err) {
      return res.status(403).json({ error: 'CORS Error: origin not allowed', origin: req.headers.origin });
    }
    return next();
  });
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Increase header size limit for Firebase tokens
// This needs to be set before creating the Express app
const http = require('http');
const server = http.createServer(app);
server.maxHeadersCount = 2000; // Increase max headers
server.headersTimeout = 60000; // Increase timeout

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Static files
app.use('/uploads', express.static('uploads'));

// Health check endpoint - HTML page with DB, Firebase, Firebase Storage status
app.get('/health', async (req, res) => {
  const checks = { db: { ok: false, message: '' }, firebase: { ok: false, message: '' }, firebaseStorage: { ok: false, message: '', testUrl: null } };

  // 1. Database connection
  try {
    await sequelize.authenticate();
    checks.db = { ok: true, message: 'Connected successfully' };
  } catch (err) {
    checks.db = { ok: false, message: err.message || 'Connection failed' };
  }

  // 2. Firebase (Auth/Firestore)
  try {
    const { db } = getFirebaseInstance();
    await db.collection('_health_check').limit(1).get();
    checks.firebase = { ok: true, message: 'Connected successfully' };
  } catch (err) {
    checks.firebase = { ok: false, message: err.message || 'Not initialized or connection failed' };
  }

  // 3. Firebase Storage - actual test upload
  if (isGCSAvailable()) {
    try {
      const minimalPng = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQwAADgAEA4T3bKQAAAABJRU5ErkJggg==', 'base64');
      const result = await uploadToGCS(minimalPng, 'health-check-test.png', 'health-check', 'image/png');
      checks.firebaseStorage = { ok: true, message: 'Upload test passed', testUrl: result.url };
      try { await deleteFromGCS(result.fileName); } catch { /* cleanup best-effort */ }
    } catch (err) {
      checks.firebaseStorage = { ok: false, message: err.message || 'Upload test failed' };
    }
  } else {
    checks.firebaseStorage = { ok: false, message: 'Firebase Storage not configured' };
  }

  const ts = new Date().toISOString();
  const uptime = Math.floor(process.uptime());
  const html = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vizidot API Health</title>
<style>body{font-family:system-ui,sans-serif;max-width:600px;margin:2rem auto;padding:0 1rem;color:#333}
h1{color:#111;margin-bottom:.5rem}h2{font-size:1rem;color:#666;margin-top:2rem}
.item{display:flex;align-items:center;gap:.75rem;padding:.5rem 0;border-bottom:1px solid #eee}
.status{font-weight:600;min-width:100px}.ok{color:#059669}.fail{color:#dc2626}
pre{background:#f5f5f5;padding:.5rem;font-size:.85rem;overflow-x:auto;margin:.25rem 0 0}
a{color:#2563eb}</style>
</head>
<body>
<h1>Vizidot API Health Check</h1>
<p>Timestamp: ${ts} &bull; Uptime: ${uptime}s &bull; Env: ${process.env.NODE_ENV || 'development'}</p>

<h2>Database (MySQL)</h2>
<div class="item"><span class="status ${checks.db.ok ? 'ok' : 'fail'}">${checks.db.ok ? '✓ Connected' : '✗ Failed'}</span><span>${checks.db.message}</span></div>

<h2>Firebase (Auth/Firestore)</h2>
<div class="item"><span class="status ${checks.firebase.ok ? 'ok' : 'fail'}">${checks.firebase.ok ? '✓ Connected' : '✗ Failed'}</span><span>${checks.firebase.message}</span></div>

<h2>Firebase Storage</h2>
<div class="item"><span class="status ${checks.firebaseStorage.ok ? 'ok' : 'fail'}">${checks.firebaseStorage.ok ? '✓ Working' : '✗ Failed'}</span><span>${checks.firebaseStorage.message}</span></div>
${checks.firebaseStorage.testUrl ? `<p><a href="${checks.firebaseStorage.testUrl}" target="_blank">Test upload (1x1 PNG)</a></p>` : ''}
${!checks.firebaseStorage.ok && checks.firebaseStorage.message ? `<pre>${checks.firebaseStorage.message}</pre>` : ''}

<p style="margin-top:2rem;font-size:.9rem;color:#666">API: <a href="/api/v1">/api/v1</a></p>
</body>
</html>`;

  if (req.accepts('json')) {
    return res.json({
      status: checks.db.ok && checks.firebase.ok && checks.firebaseStorage.ok ? 'OK' : 'DEGRADED',
      timestamp: ts,
      uptime,
      environment: process.env.NODE_ENV,
      checks
    });
  }
  res.setHeader('Content-Type', 'text/html').send(html);
});

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/businesses', businessRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/units', unitRoutes);
app.use('/api/v1/music', musicRoutes);
app.use('/api/v1/media', mediaRoutes);
// Backward-compat alias to support frontend calling /businesses directly (dev proxy)
app.use('/businesses', businessRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Error handling middleware
app.use(errorHandler);

// Initialize database and Firebase (listen first so API stays up even if DB fails)
const initializeApp = async () => {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🔗 API Base URL: http://localhost:${PORT}/api/v1`);
  });

  try {
    await initializeFirebase();
    console.log('🔥 Firebase initialized successfully');
    const gcsOk = initializeFirebaseStorage();
    if (!gcsOk) console.warn('⚠️  Firebase Storage (GCS) not available.');
    await sequelize.authenticate();
    global.dbConnected = true;
    console.log('✅ Database connection established successfully');
  } catch (error) {
    console.error('❌ Initialization error (server still running):', error.message);
    global.dbConnected = false;
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.log('Unhandled Rejection at:', promise, 'reason:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.log('Uncaught Exception thrown:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  sequelize.close().then(() => {
    console.log('Database connection closed.');
    process.exit(0);
  });
});

initializeApp();

