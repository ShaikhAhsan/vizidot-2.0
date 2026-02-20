const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const { Artist, ArtistFollower, Album, AudioTrack, VideoTrack, ArtistShop } = require('../models');
const { authenticateToken, optionalAuth } = require('../middleware/authWithRoles');

function formatDuration(seconds) {
  if (seconds == null || isNaN(seconds)) return null;
  const m = Math.floor(Number(seconds) / 60);
  const s = Math.floor(Number(seconds) % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

// Confirm music router is mounted: GET /api/v1/music
router.get('/', (req, res) => {
  res.json({
    api: 'app',
    module: 'music',
    endpoints: [
      'GET /artists/profile/:id',
      'POST /artists/:id/follow',
      'DELETE /artists/:id/follow'
    ]
  });
});

/**
 * GET /api/v1/music/artists/profile/:id
 * Public artist profile. If Authorization header is sent, response includes isFollowing (1/0) for current user.
 */
router.get('/artists/profile/:id', optionalAuth, async (req, res) => {
  try {
    const artistId = parseInt(req.params.id, 10);
    if (Number.isNaN(artistId) || artistId < 1) {
      return res.status(400).json({ success: false, error: 'Invalid artist id' });
    }

    const artist = await Artist.findByPk(artistId, {
      include: [{ model: ArtistShop, as: 'shop', required: false }]
    });
    if (!artist || !artist.is_active) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }

    const userId = req.user?.id || req.userId;
    let isFollowing = 0;
    if (userId) {
      const followRow = await ArtistFollower.findOne({
        where: { user_id: userId, artist_id: artistId }
      });
      isFollowing = followRow ? 1 : 0;
    }

    const followersCount = await ArtistFollower.count({ where: { artist_id: artistId } });
    const followingCount = 0; // optional: count artists this user follows; not in schema for "artist follows X"

    const allAlbums = await Album.findAll({
      where: { artist_id: artistId, is_active: true },
      order: [['release_date', 'DESC'], ['album_id', 'ASC']]
    });
    const albumType = (a) => String(a.album_type || '').toLowerCase();
    const audioAlbums = allAlbums.filter((a) => albumType(a) === 'audio');
    const videoAlbums = allAlbums.filter((a) => albumType(a) === 'video');
    const audioAlbumIds = audioAlbums.map((a) => a.album_id);
    const videoAlbumIds = videoAlbums.map((a) => a.album_id);

    const audioTracks =
      audioAlbumIds.length > 0
        ? await AudioTrack.findAll({
            where: { album_id: { [Op.in]: audioAlbumIds } },
            order: [['album_id', 'ASC'], ['track_number', 'ASC'], ['audio_id', 'ASC']]
          })
        : [];
    const videoTracks =
      videoAlbumIds.length > 0
        ? await VideoTrack.findAll({
            where: { album_id: { [Op.in]: videoAlbumIds } },
            order: [['album_id', 'ASC'], ['track_number', 'ASC'], ['video_id', 'ASC']]
          })
        : [];

    const artistName = artist.name || '';
    const payload = {
      success: true,
      data: {
        profileVersion: 2,
        artist: {
          id: artist.artist_id,
          name: artistName,
          bio: artist.bio ?? null,
          imageUrl: artist.image_url ?? null,
          followersCount,
          followingCount,
          isFollowing,
          shopId: artist.shop_id ?? null,
          shop: artist.shop
            ? {
                id: artist.shop.shop_id,
                shopName: artist.shop.shop_name,
                shopUrl: artist.shop.shop_url
              }
            : null
        },
        albums: audioAlbums.map((a) => ({
          id: a.album_id,
          title: a.title,
          coverImageUrl: a.cover_image_url ?? null,
          artistName
        })),
        tracks: audioTracks.map((t) => ({
          id: t.audio_id,
          title: t.title,
          durationFormatted: formatDuration(t.duration),
          durationSeconds: t.duration ?? null,
          albumArt: t.thumbnail_url ?? (audioAlbums.find((a) => a.album_id === t.album_id)?.cover_image_url) ?? null,
          artistName,
          audioUrl: t.audio_url ?? null,
          albumId: t.album_id
        })),
        videoAlbums: videoAlbums.map((a) => ({
          id: a.album_id,
          title: a.title,
          coverImageUrl: a.cover_image_url ?? null,
          artistName
        })),
        videos: videoTracks.map((t) => ({
          id: t.video_id,
          title: t.title,
          durationFormatted: formatDuration(t.duration),
          durationSeconds: t.duration ?? null,
          albumArt: t.thumbnail_url ?? (videoAlbums.find((a) => a.album_id === t.album_id)?.cover_image_url) ?? null,
          artistName,
          videoUrl: t.video_url ?? null,
          albumId: t.album_id
        }))
      }
    };
    return res.json(payload);
  } catch (err) {
    console.error('Artist profile error:', err);
    return res.status(500).json({ success: false, error: 'Could not load artist profile' });
  }
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
