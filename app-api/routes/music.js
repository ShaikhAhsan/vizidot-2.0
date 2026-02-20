const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const { Artist, ArtistFollower, Album, AudioTrack, VideoTrack, ArtistShop, UserFavourite } = require('../models');
const { authenticateToken, optionalAuth } = require('../middleware/authWithRoles');

function formatDuration(seconds) {
  if (seconds == null || isNaN(seconds)) return null;
  const m = Math.floor(Number(seconds) / 60);
  const s = Math.floor(Number(seconds) % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

// Confirm music router is mounted: GET /api/v1/music
const VALID_ENTITY_TYPES = ['album', 'track', 'video'];

router.get('/', (req, res) => {
  res.json({
    api: 'app',
    module: 'music',
    endpoints: [
      'GET /artists/profile/:id',
      'GET /albums/:id',
      'POST /artists/:id/follow',
      'DELETE /artists/:id/follow',
      'POST /favourites',
      'DELETE /favourites/:type/:id',
      'GET /favourites',
      'GET /favourites/check'
    ]
  });
});

/**
 * GET /api/v1/music/albums/:id
 * Album detail: album info + tracks (audio or video by album_type). Public.
 */
router.get('/albums/:id', async (req, res) => {
  try {
    const albumId = parseInt(req.params.id, 10);
    if (Number.isNaN(albumId) || albumId < 1) {
      return res.status(400).json({ success: false, error: 'Invalid album id' });
    }

    const album = await Album.findByPk(albumId, {
      include: [{ model: Artist, as: 'artist', attributes: ['artist_id', 'name'] }]
    });
    if (!album || !album.is_active) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }

    const artistName = album.artist?.name || '';
    const albumType = String(album.album_type || '').toLowerCase();
    const isVideo = albumType === 'video';

    let tracks = [];
    if (isVideo) {
      const videoTracks = await VideoTrack.findAll({
        where: { album_id: albumId },
        order: [['track_number', 'ASC'], ['video_id', 'ASC']]
      });
      tracks = videoTracks.map((t) => ({
        id: t.video_id,
        title: t.title,
        durationFormatted: formatDuration(t.duration),
        durationSeconds: t.duration ?? null,
        albumArt: t.thumbnail_url ?? album.cover_image_url ?? null,
        artistName,
        videoUrl: t.video_url ?? null,
        albumId: t.album_id,
        type: 'video'
      }));
    } else {
      const audioTracks = await AudioTrack.findAll({
        where: { album_id: albumId },
        order: [['track_number', 'ASC'], ['audio_id', 'ASC']]
      });
      tracks = audioTracks.map((t) => ({
        id: t.audio_id,
        title: t.title,
        durationFormatted: formatDuration(t.duration),
        durationSeconds: t.duration ?? null,
        albumArt: t.thumbnail_url ?? album.cover_image_url ?? null,
        artistName,
        audioUrl: t.audio_url ?? null,
        albumId: t.album_id,
        type: 'audio'
      }));
    }

    const releaseYear = album.release_date
      ? String(album.release_date).slice(0, 4)
      : null;
    const totalSeconds = tracks.reduce((sum, t) => sum + (t.durationSeconds || 0), 0);
    const totalMins = Math.floor(totalSeconds / 60);
    const totalDurationFormatted =
      totalMins >= 60 ? `${Math.floor(totalMins / 60)}h ${totalMins % 60}min` : `${totalMins} min`;

    return res.json({
      success: true,
      data: {
        album: {
          id: album.album_id,
          title: album.title,
          description: album.description ?? null,
          coverImageUrl: album.cover_image_url ?? null,
          artistId: album.artist_id,
          artistName,
          albumType: isVideo ? 'video' : 'audio',
          releaseDate: album.release_date,
          releaseYear,
          trackCount: tracks.length,
          totalDurationFormatted
        },
        tracks
      }
    });
  } catch (err) {
    console.error('Album detail error:', err);
    return res.status(500).json({ success: false, error: 'Could not load album' });
  }
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

// ---------- Favourites (albums, tracks, videos) — require auth ----------

/**
 * POST /api/v1/music/favourites
 * Add album, track (audio), or video to user's favourites.
 * Body: { entityType: 'album'|'track'|'video', entityId: number }
 */
router.post('/favourites', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    const { entityType, entityId } = req.body || {};
    if (!entityType || !VALID_ENTITY_TYPES.includes(String(entityType).toLowerCase())) {
      return res.status(400).json({ success: false, error: 'Invalid entityType; use album, track, or video' });
    }
    const id = parseInt(entityId, 10);
    if (Number.isNaN(id) || id < 1) {
      return res.status(400).json({ success: false, error: 'Invalid entityId' });
    }
    const type = String(entityType).toLowerCase();
    const [row, created] = await UserFavourite.findOrCreate({
      where: { user_id: userId, entity_type: type, entity_id: id },
      defaults: { user_id: userId, entity_type: type, entity_id: id }
    });
    return res.status(created ? 201 : 200).json({
      success: true,
      message: created ? 'Added to favourites' : 'Already in favourites',
      data: { favourited: true }
    });
  } catch (err) {
    console.error('Add favourite error:', err.message, err.sql || '');
    return res.status(500).json({ success: false, error: 'Could not add favourite' });
  }
});

/**
 * DELETE /api/v1/music/favourites/:type/:id
 * Remove album, track, or video from user's favourites.
 */
router.delete('/favourites/:type/:id', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    const type = String(req.params.type || '').toLowerCase();
    const id = parseInt(req.params.id, 10);
    if (!VALID_ENTITY_TYPES.includes(type) || Number.isNaN(id) || id < 1) {
      return res.status(400).json({ success: false, error: 'Invalid type or id' });
    }
    const deleted = await UserFavourite.destroy({
      where: { user_id: userId, entity_type: type, entity_id: id }
    });
    return res.status(200).json({
      success: true,
      message: deleted ? 'Removed from favourites' : 'Was not in favourites',
      data: { favourited: false }
    });
  } catch (err) {
    console.error('Remove favourite error:', err);
    return res.status(500).json({ success: false, error: 'Could not remove favourite' });
  }
});

/**
 * GET /api/v1/music/favourites/check?type=album&id=1
 * Check if current user has this album/track/video in favourites.
 * Must be defined before GET /favourites so "check" is not matched as :type.
 */
router.get('/favourites/check', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    const type = req.query.type ? String(req.query.type).toLowerCase() : null;
    const id = req.query.id != null ? parseInt(req.query.id, 10) : NaN;
    if (!type || !VALID_ENTITY_TYPES.includes(type) || Number.isNaN(id) || id < 1) {
      return res.status(400).json({ success: false, error: 'Query type and id required (e.g. type=album&id=1)' });
    }
    const row = await UserFavourite.findOne({
      where: { user_id: userId, entity_type: type, entity_id: id }
    });
    return res.json({
      success: true,
      data: { favourited: !!row }
    });
  } catch (err) {
    console.error('Check favourite error:', err);
    return res.status(500).json({ success: false, error: 'Could not check favourite' });
  }
});

/**
 * GET /api/v1/music/favourites
 * List user's favourites. Query: ?type=album|track|video (optional).
 */
router.get('/favourites', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id || req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }
    const type = req.query.type ? String(req.query.type).toLowerCase() : null;
    const where = { user_id: userId };
    if (type && VALID_ENTITY_TYPES.includes(type)) where.entity_type = type;
    const list = await UserFavourite.findAll({
      where,
      order: [['created_at', 'DESC']],
      attributes: ['id', 'entity_type', 'entity_id', 'created_at']
    });
    return res.json({
      success: true,
      data: {
        favourites: list.map((f) => ({
          id: f.id,
          entityType: f.entity_type,
          entityId: f.entity_id,
          createdAt: f.created_at
        }))
      }
    });
  } catch (err) {
    console.error('List favourites error:', err);
    return res.status(500).json({ success: false, error: 'Could not list favourites' });
  }
});

module.exports = router;
