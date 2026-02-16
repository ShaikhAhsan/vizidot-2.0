const express = require('express');
const router = express.Router();

/**
 * App API – Order routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'orders', message: 'Add order routes here' });
});

module.exports = router;
