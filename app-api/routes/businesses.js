const express = require('express');
const router = express.Router();

/**
 * App API – Business routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'businesses', message: 'Add business routes here' });
});

module.exports = router;
