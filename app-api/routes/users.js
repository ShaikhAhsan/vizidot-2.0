const express = require('express');
const router = express.Router();

/**
 * App API – User routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'users', message: 'Add user routes here' });
});

module.exports = router;
