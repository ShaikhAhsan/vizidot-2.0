const express = require('express');
const router = express.Router();

/**
 * App API – Upload routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'upload', message: 'Add upload routes here' });
});

module.exports = router;
