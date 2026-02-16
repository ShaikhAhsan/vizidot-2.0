const express = require('express');
const router = express.Router();

/**
 * App API – Admin-related routes (if any for the app)
 * Admin Panel CRUD uses a separate API – this is for app-only admin actions.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'admin', message: 'Add app admin routes here' });
});

module.exports = router;
