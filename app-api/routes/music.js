const express = require('express');
const router = express.Router();

/**
 * App API – Music / artist routes
 * Add new routes here (e.g. artist profile, follow, albums, tracks).
 * Admin Panel uses a separate API.
 */

router.get('/', (req, res) => {
  res.json({ api: 'app', module: 'music', message: 'Add music/artist routes here' });
});

module.exports = router;
