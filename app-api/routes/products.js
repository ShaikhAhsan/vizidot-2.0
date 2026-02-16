const express = require('express');
const router = express.Router();

/**
 * App API – Product routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'products', message: 'Add product routes here' });
});

module.exports = router;
