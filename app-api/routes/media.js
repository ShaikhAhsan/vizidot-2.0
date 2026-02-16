const express = require('express');
const router = express.Router();

/**
 * App API – Media routes
 * Add new routes here. Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'media', message: 'Add media routes here' });
});

module.exports = router;
