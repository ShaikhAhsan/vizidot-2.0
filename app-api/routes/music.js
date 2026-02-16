const express = require('express');
const router = express.Router();
const { Artist, ArtistFollower } = require('../models');
const { authenticateToken } = require('../middleware/authWithRoles');

// Confirm music router is mounted: GET /api/v1/music
router.get('/', (req, res) => {
  res.json({
    api: 'app',
    module: 'music',
    endpoints: [
      'POST /artists/:id/follow',
      'DELETE /artists/:id/follow'
    ]
  });
});

/**
 * POST /api/v1/music/artists/:id/follow
 * Follow an artist. Requires auth (Bearer token or dev user).
 */
router.post('/artists/:id/follow', authenticateToken, async (req, res) => {
  try {
    const artistId = parseInt(req.params.id, 10);
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    if (Number.isNaN(artistId) || artistId < 1) {
      return res.status(400).json({ success: false, error: 'Invalid artist id' });
    }

    const artist = await Artist.findByPk(artistId);
    if (!artist || !artist.is_active) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }

    const [row, created] = await ArtistFollower.findOrCreate({
      where: { user_id: userId, artist_id: artistId },
      defaults: { user_id: userId, artist_id: artistId }
    });

    return res.status(created ? 201 : 200).json({
      success: true,
      message: created ? 'Following artist' : 'Already following',
      data: { following: true }
    });
  } catch (err) {
    console.error('Follow artist error:', err);
    return res.status(500).json({ success: false, error: 'Could not follow artist' });
  }
});

/**
 * DELETE /api/v1/music/artists/:id/follow
 * Unfollow an artist. Requires auth.
 */
router.delete('/artists/:id/follow', authenticateToken, async (req, res) => {
  try {
    const artistId = parseInt(req.params.id, 10);
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    if (Number.isNaN(artistId) || artistId < 1) {
      return res.status(400).json({ success: false, error: 'Invalid artist id' });
    }

    const deleted = await ArtistFollower.destroy({
      where: { user_id: userId, artist_id: artistId }
    });

    return res.status(200).json({
      success: true,
      message: deleted ? 'Unfollowed artist' : 'Was not following',
      data: { following: false }
    });
  } catch (err) {
    console.error('Unfollow artist error:', err);
    return res.status(500).json({ success: false, error: 'Could not unfollow artist' });
  }
});

module.exports = router;
