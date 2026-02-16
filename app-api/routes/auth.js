const express = require('express');
const router = express.Router();

/**
 * App API – Auth routes
 * Add new routes here (e.g. POST /login, POST /register).
 * Admin Panel uses a separate API.
 */

// Stub: replace with real implementation
router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'auth', message: 'Add auth routes here' });
});

module.exports = router;
