const express = require('express');
const router = express.Router();

/**
 * App API – Unit routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'units', message: 'Add unit routes here' });
});

module.exports = router;
