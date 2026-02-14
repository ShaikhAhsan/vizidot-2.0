const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const { authenticateToken, requireSystemAdmin } = require('../middleware/authWithRoles');
const {
  Artist,
  ArtistBranding,
  ArtistShop,
  Album,
  AudioTrack,
  VideoTrack,
  AlbumArtist,
  TrackArtist,
  BrandingArtist,
  ShopArtist
} = require('../models');

// ============================================================
// PUBLIC API: Artist profile for app (no auth required)
// ============================================================
/**
 * @route GET /api/v1/music/artists/profile/:id
 * @desc Get artist profile with albums and tracks for app detail view
 * @access Public
 */
router.get('/artists/profile/:id', async (req, res) => {
  try {
    const artistId = req.params.id;
    const artist = await Artist.findByPk(artistId, {
      include: [
        { model: ArtistShop, as: 'shop', required: false },
        {
          model: Album,
          as: 'albums',
          required: false,
          where: { is_active: true },
          include: [
            { model: AudioTrack, as: 'audioTracks', required: false }
          ]
        }
      ]
    });

    if (!artist || !artist.is_active) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }

    const artistJson = artist.toJSON();
    const albums = artistJson.albums || [];
    const artistName = artist.name;

    // Build album list for app (id, title, coverImageUrl, artistName)
    const albumsForApp = albums.map((a) => ({
      id: a.album_id,
      title: a.title,
      coverImageUrl: a.cover_image_url || a.default_track_thumbnail || null,
      artistName
    }));

    // Build flat track list from all albums (id, title, durationFormatted, albumArt, artistName, audioUrl)
    const formatDuration = (seconds) => {
      if (seconds == null) return '0:00';
      const m = Math.floor(seconds / 60);
      const s = Math.floor(seconds % 60);
      return `${m}:${s.toString().padStart(2, '0')}`;
    };
    const tracksForApp = [];
    for (const album of albums) {
      const audioTracks = album.audioTracks || [];
      const coverUrl = album.cover_image_url || album.default_track_thumbnail || null;
      for (const t of audioTracks) {
        tracksForApp.push({
          id: t.audio_id,
          title: t.title,
          durationFormatted: formatDuration(t.duration),
          durationSeconds: t.duration,
          albumArt: t.thumbnail_url || coverUrl,
          artistName,
          audioUrl: t.audio_url,
          albumId: album.album_id
        });
      }
    }

    // Followers/following: return 0 until artist_followers table exists (see DATABASE_SCHEMA_MUSIC.md)
    const followersCount = 0;
    const followingCount = 0;

    res.json({
      success: true,
      data: {
        artist: {
          id: artistJson.artist_id,
          name: artistJson.name,
          bio: artistJson.bio,
          imageUrl: artistJson.image_url,
          followersCount,
          followingCount,
          shopId: artistJson.shop_id,
          shop: artistJson.shop ? {
            id: artistJson.shop.shop_id,
            shopName: artistJson.shop.shop_name,
            shopUrl: artistJson.shop.shop_url
          } : null
        },
        albums: albumsForApp,
        tracks: tracksForApp
      }
    });
  } catch (error) {
    console.error('Artist profile error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Apply authentication and admin role to all routes below
router.use(authenticateToken);
router.use(requireSystemAdmin);

// ============================================================
// ARTISTS CRUD
// ============================================================

router.get('/artists', async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', includeDeleted = false, artist_id } = req.query;
    const offset = (page - 1) * limit;
    
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { country: { [Op.like]: `%${search}%` } }
      ];
    }
    
    // Filter by artist_id if provided
    if (artist_id) {
      whereClause.artist_id = parseInt(artist_id);
    }
    
    // Use withDeleted scope if needed, otherwise use default scope (no need to specify)
    const queryOptions = {
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
      include: [
        { model: ArtistBranding, as: 'brandings', required: false },
        { model: ArtistShop, as: 'shop', required: false }
      ]
    };
    
    const { count, rows: artists } = includeDeleted === 'true' 
      ? await Artist.scope('withDeleted').findAndCountAll(queryOptions)
      : await Artist.findAndCountAll(queryOptions);

    res.json({
      success: true,
      data: artists,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/artists/deleted', async (req, res) => {
  try {
    const artists = await Artist.scope('deleted').findAll({
      order: [['deleted_at', 'DESC']]
    });
    res.json({ success: true, data: artists });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/artists/:id', async (req, res) => {
  try {
    const artist = await Artist.findByPk(req.params.id, {
      include: [
        { model: ArtistBranding, as: 'brandings', required: false },
        { model: ArtistShop, as: 'shop', required: false },
        { model: Album, as: 'albums', required: false }
      ]
    });
    if (!artist) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }
    res.json({ success: true, data: artist });
  } catch (error) {
    console.error('Error fetching artist:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/artists', async (req, res) => {
  try {
    const artist = await Artist.create(req.body);
    res.status(201).json({ success: true, data: artist });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/artists/:id', async (req, res) => {
  try {
    const artist = await Artist.findByPk(req.params.id);
    if (!artist) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }
    
    const { brandings, shop_id, ...artistData } = req.body;
    
    // Handle shop_id (one-to-one relationship)
    if (shop_id !== undefined) {
      artistData.shop_id = shop_id || null;
    }
    
    await artist.update(artistData);
    
    // Handle many-to-many brandings
    if (Array.isArray(brandings)) {
      await artist.setBrandings(brandings);
    }
    
    // Reload with associations
    await artist.reload({
      include: [
        { model: ArtistBranding, as: 'brandings', required: false },
        { model: ArtistShop, as: 'shop', required: false }
      ]
    });
    
    res.json({ success: true, data: artist });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/artists/:id', async (req, res) => {
  try {
    const artist = await Artist.findByPk(req.params.id);
    if (!artist) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }
    await artist.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Artist soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/artists/:id/restore', async (req, res) => {
  try {
    const artist = await Artist.scope('withDeleted').findByPk(req.params.id);
    if (!artist) {
      return res.status(404).json({ success: false, error: 'Artist not found' });
    }
    await artist.update({
      is_deleted: false,
      deleted_at: null
    });
    res.json({ success: true, data: artist });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// BRANDINGS CRUD
// ============================================================

router.get('/brandings', async (req, res) => {
  try {
    const { artist_id, includeDeleted = false } = req.query;
    let whereClause = {};
    
    if (artist_id) {
      // Filter by artist through junction table
      const brandingsWithArtist = await BrandingArtist.findAll({
        where: { artist_id }
      });
      const brandingIds = brandingsWithArtist.map(b => b.branding_id);
      if (brandingIds.length > 0) {
        whereClause.branding_id = { [Op.in]: brandingIds };
      } else {
        whereClause.branding_id = { [Op.in]: [] }; // No results
      }
    }
    
    const queryOptions = {
      where: whereClause,
      include: [
        { model: Artist, as: 'primaryArtist', required: false },
        { model: Artist, as: 'artists', required: false }
      ],
      order: [['created_at', 'DESC']]
    };
    
    const brandings = includeDeleted === 'true'
      ? await ArtistBranding.scope('withDeleted').findAll(queryOptions)
      : await ArtistBranding.findAll(queryOptions);
    res.json({ success: true, data: brandings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/brandings/:id', async (req, res) => {
  try {
    const branding = await ArtistBranding.findByPk(req.params.id, {
      include: [
        { model: Artist, as: 'primaryArtist', required: false },
        { model: Artist, as: 'artists', required: false }
      ]
    });
    if (!branding) {
      return res.status(404).json({ success: false, error: 'Branding not found' });
    }
    res.json({ success: true, data: branding });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/brandings', async (req, res) => {
  try {
    const { artists, artist_id, ...brandingData } = req.body; // Also exclude artist_id if present
    const branding = await ArtistBranding.create(brandingData);
    
    // Handle many-to-many artists
    if (Array.isArray(artists) && artists.length > 0) {
      await branding.setArtists(artists);
    }
    
    // Reload with associations
    await branding.reload({
      include: [{ model: Artist, as: 'artists', required: false }]
    });
    
    res.status(201).json({ success: true, data: branding });
  } catch (error) {
    console.error('Error creating branding:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/brandings/:id', async (req, res) => {
  try {
    const branding = await ArtistBranding.findByPk(req.params.id);
    if (!branding) {
      return res.status(404).json({ success: false, error: 'Branding not found' });
    }
    
    const { artists, ...brandingData } = req.body;
    await branding.update(brandingData);
    
    // Handle many-to-many artists
    if (Array.isArray(artists)) {
      await branding.setArtists(artists);
    }
    
    // Reload with associations
    await branding.reload({
      include: [{ model: Artist, as: 'artists', required: false }]
    });
    
    res.json({ success: true, data: branding });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/brandings/:id', async (req, res) => {
  try {
    const branding = await ArtistBranding.findByPk(req.params.id);
    if (!branding) {
      return res.status(404).json({ success: false, error: 'Branding not found' });
    }
    await branding.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Branding soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// SHOPS CRUD
// ============================================================

router.get('/shops', async (req, res) => {
  try {
    const { artist_id, branding_id, includeDeleted = false } = req.query;
    let whereClause = {};
    
    if (artist_id) {
      // Filter by artist through shop_id foreign key (one-to-many relationship)
      const artist = await Artist.findByPk(artist_id);
      if (artist && artist.shop_id) {
        whereClause.shop_id = artist.shop_id;
      } else {
        whereClause.shop_id = { [Op.in]: [] }; // No results if artist has no shop
      }
    }
    if (branding_id) whereClause.branding_id = branding_id;
    
    const queryOptions = {
      where: whereClause,
      include: [
        { model: Artist, as: 'primaryArtist', required: false },
        { model: Artist, as: 'artists', required: false }, // Artists assigned via shop_id
        { model: ArtistBranding, as: 'branding', required: false }
      ],
      order: [['created_at', 'DESC']]
    };
    
    const shops = includeDeleted === 'true'
      ? await ArtistShop.scope('withDeleted').findAll(queryOptions)
      : await ArtistShop.findAll(queryOptions);
    res.json({ success: true, data: shops });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/shops/:id', async (req, res) => {
  try {
    const shop = await ArtistShop.findByPk(req.params.id, {
      include: [
        { model: Artist, as: 'primaryArtist', required: false },
        { model: Artist, as: 'artists', required: false },
        { model: ArtistBranding, as: 'branding', required: false }
      ]
    });
    if (!shop) {
      return res.status(404).json({ success: false, error: 'Shop not found' });
    }
    res.json({ success: true, data: shop });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/shops', async (req, res) => {
  try {
    const { artists, artist_id, ...shopData } = req.body; // Also exclude artist_id if present
    const shop = await ArtistShop.create(shopData);
    
    // Handle many-to-many artists
    if (Array.isArray(artists) && artists.length > 0) {
      await shop.setArtists(artists);
    }
    
    // Reload with associations
    await shop.reload({
      include: [{ model: Artist, as: 'artists', required: false }]
    });
    
    res.status(201).json({ success: true, data: shop });
  } catch (error) {
    console.error('Error creating shop:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/shops/:id', async (req, res) => {
  try {
    const shop = await ArtistShop.findByPk(req.params.id);
    if (!shop) {
      return res.status(404).json({ success: false, error: 'Shop not found' });
    }
    
    const { artists, ...shopData } = req.body;
    await shop.update(shopData);
    
    // Handle many-to-many artists
    if (Array.isArray(artists)) {
      await shop.setArtists(artists);
    }
    
    // Reload with associations
    await shop.reload({
      include: [{ model: Artist, as: 'artists', required: false }]
    });
    
    res.json({ success: true, data: shop });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/shops/:id', async (req, res) => {
  try {
    const shop = await ArtistShop.findByPk(req.params.id);
    if (!shop) {
      return res.status(404).json({ success: false, error: 'Shop not found' });
    }
    await shop.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Shop soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// ALBUMS CRUD
// ============================================================

router.get('/albums', async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', artist_id, album_type, includeDeleted = false } = req.query;
    const offset = (page - 1) * limit;
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } }
      ];
    }
    if (artist_id) whereClause.artist_id = artist_id;
    if (album_type) whereClause.album_type = album_type;
    
    const queryOptions = {
      where: whereClause,
      include: [
        { model: Artist, as: 'artist', required: false },
        { model: ArtistBranding, as: 'branding', required: false }
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']]
    };
    
    const { count, rows: albums } = includeDeleted === 'true'
      ? await Album.scope('withDeleted').findAndCountAll(queryOptions)
      : await Album.findAndCountAll(queryOptions);

    res.json({
      success: true,
      data: albums, // This is already the rows array from findAndCountAll
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/albums/:id', async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.id, {
      include: [
        { model: Artist, as: 'artist', required: false },
        { model: ArtistBranding, as: 'branding', required: false },
        { model: AudioTrack, as: 'audioTracks', required: false },
        { model: VideoTrack, as: 'videoTracks', required: false },
        { model: Artist, as: 'collaboratingArtists', through: { attributes: ['role'] }, required: false }
      ]
    });
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    
    const albumData = album.toJSON();
    
    // Populate empty thumbnail_url with album's default_track_thumbnail for audio tracks
    if (albumData.audioTracks && album.default_track_thumbnail) {
      albumData.audioTracks = albumData.audioTracks.map(track => {
        if (!track.thumbnail_url) {
          track.thumbnail_url = album.default_track_thumbnail;
        }
        return track;
      });
    }
    
    // Populate empty thumbnail_url with album's default_track_thumbnail for video tracks
    if (albumData.videoTracks && album.default_track_thumbnail) {
      albumData.videoTracks = albumData.videoTracks.map(track => {
        if (!track.thumbnail_url) {
          track.thumbnail_url = album.default_track_thumbnail;
        }
        return track;
      });
    }
    
    res.json({ success: true, data: albumData });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/albums', async (req, res) => {
  try {
    const album = await Album.create(req.body);
    res.status(201).json({ success: true, data: album });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/albums/:id', async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.id);
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    await album.update(req.body);
    res.json({ success: true, data: album });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/albums/:id', async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.id);
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    await album.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Album soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// AUDIO TRACKS CRUD
// ============================================================

router.get('/albums/:albumId/audio-tracks', async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.albumId);
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    
    const tracks = await AudioTrack.findAll({
      where: { album_id: req.params.albumId },
      order: [['track_number', 'ASC']]
    });
    
    // Populate empty thumbnail_url with album's default_track_thumbnail
    const tracksWithDefaults = tracks.map(track => {
      const trackData = track.toJSON();
      if (!trackData.thumbnail_url && album.default_track_thumbnail) {
        trackData.thumbnail_url = album.default_track_thumbnail;
      }
      return trackData;
    });
    
    res.json({ success: true, data: tracksWithDefaults });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/albums/:albumId/audio-tracks', async (req, res) => {
  try {
    const track = await AudioTrack.create({
      ...req.body,
      album_id: req.params.albumId
    });
    res.status(201).json({ success: true, data: track });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/audio-tracks/:id', async (req, res) => {
  try {
    const track = await AudioTrack.findByPk(req.params.id);
    if (!track) {
      return res.status(404).json({ success: false, error: 'Audio track not found' });
    }
    await track.update(req.body);
    res.json({ success: true, data: track });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/audio-tracks/:id', async (req, res) => {
  try {
    const track = await AudioTrack.findByPk(req.params.id);
    if (!track) {
      return res.status(404).json({ success: false, error: 'Audio track not found' });
    }
    await track.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Audio track soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// VIDEO TRACKS CRUD
// ============================================================

router.get('/albums/:albumId/video-tracks', async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.albumId);
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    
    const tracks = await VideoTrack.findAll({
      where: { album_id: req.params.albumId },
      order: [['track_number', 'ASC']]
    });
    
    // Populate empty thumbnail_url with album's default_track_thumbnail
    const tracksWithDefaults = tracks.map(track => {
      const trackData = track.toJSON();
      if (!trackData.thumbnail_url && album.default_track_thumbnail) {
        trackData.thumbnail_url = album.default_track_thumbnail;
      }
      return trackData;
    });
    
    res.json({ success: true, data: tracksWithDefaults });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/albums/:albumId/video-tracks', async (req, res) => {
  try {
    const track = await VideoTrack.create({
      ...req.body,
      album_id: req.params.albumId
    });
    res.status(201).json({ success: true, data: track });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/video-tracks/:id', async (req, res) => {
  try {
    const track = await VideoTrack.findByPk(req.params.id);
    if (!track) {
      return res.status(404).json({ success: false, error: 'Video track not found' });
    }
    await track.update(req.body);
    res.json({ success: true, data: track });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/video-tracks/:id', async (req, res) => {
  try {
    const track = await VideoTrack.findByPk(req.params.id);
    if (!track) {
      return res.status(404).json({ success: false, error: 'Video track not found' });
    }
    await track.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Video track soft deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// COLLABORATIONS
// ============================================================

router.get('/albums/:albumId/collaborators', async (req, res) => {
  try {
    const collaborators = await AlbumArtist.findAll({
      where: { album_id: req.params.albumId },
      include: [{ model: Artist, as: 'artist' }]
    });
    res.json({ success: true, data: collaborators });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/albums/:albumId/collaborators', async (req, res) => {
  try {
    const { artist_id, role } = req.body;
    const collaborator = await AlbumArtist.create({
      album_id: req.params.albumId,
      artist_id,
      role
    });
    res.status(201).json({ success: true, data: collaborator });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete('/albums/:albumId/collaborators/:id', async (req, res) => {
  try {
    const collaborator = await AlbumArtist.findByPk(req.params.id);
    if (!collaborator) {
      return res.status(404).json({ success: false, error: 'Collaborator not found' });
    }
    await collaborator.update({
      is_deleted: true,
      deleted_at: new Date()
    });
    res.json({ success: true, message: 'Collaborator removed' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;

