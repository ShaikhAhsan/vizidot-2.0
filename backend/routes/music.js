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
  TrackArtist
} = require('../models');

// Apply authentication and admin role to all routes
router.use(authenticateToken);
router.use(requireSystemAdmin);

// ============================================================
// ARTISTS CRUD
// ============================================================

router.get('/artists', async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', includeDeleted = false } = req.query;
    const offset = (page - 1) * limit;
    
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { country: { [Op.like]: `%${search}%` } }
      ];
    }
    
    // Use withDeleted scope if needed, otherwise use default scope (no need to specify)
    const queryOptions = {
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']]
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
        { model: ArtistShop, as: 'shops', required: false },
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
    await artist.update(req.body);
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
    const whereClause = {};
    if (artist_id) whereClause.artist_id = artist_id;
    
    const queryOptions = {
      where: whereClause,
      include: [{ model: Artist, as: 'artist' }],
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
      include: [{ model: Artist, as: 'artist' }]
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
    const branding = await ArtistBranding.create(req.body);
    res.status(201).json({ success: true, data: branding });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/brandings/:id', async (req, res) => {
  try {
    const branding = await ArtistBranding.findByPk(req.params.id);
    if (!branding) {
      return res.status(404).json({ success: false, error: 'Branding not found' });
    }
    await branding.update(req.body);
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
    const whereClause = {};
    if (artist_id) whereClause.artist_id = artist_id;
    if (branding_id) whereClause.branding_id = branding_id;
    
    const queryOptions = {
      where: whereClause,
      include: [
        { model: Artist, as: 'artist' },
        { model: ArtistBranding, as: 'branding' }
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
        { model: Artist, as: 'artist' },
        { model: ArtistBranding, as: 'branding' }
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
    const shop = await ArtistShop.create(req.body);
    res.status(201).json({ success: true, data: shop });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put('/shops/:id', async (req, res) => {
  try {
    const shop = await ArtistShop.findByPk(req.params.id);
    if (!shop) {
      return res.status(404).json({ success: false, error: 'Shop not found' });
    }
    await shop.update(req.body);
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
    const { page = 1, limit = 10, artist_id, album_type, includeDeleted = false } = req.query;
    const offset = (page - 1) * limit;
    const whereClause = {};
    if (artist_id) whereClause.artist_id = artist_id;
    if (album_type) whereClause.album_type = album_type;
    
    const queryOptions = {
      where: whereClause,
      include: [
        { model: Artist, as: 'artist' },
        { model: ArtistBranding, as: 'branding' }
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
      data: albums,
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
        { model: Artist, as: 'artist' },
        { model: ArtistBranding, as: 'branding' },
        { model: AudioTrack, as: 'audioTracks' },
        { model: VideoTrack, as: 'videoTracks' },
        { model: Artist, as: 'collaboratingArtists', through: { attributes: ['role'] } }
      ]
    });
    if (!album) {
      return res.status(404).json({ success: false, error: 'Album not found' });
    }
    res.json({ success: true, data: album });
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
    const tracks = await AudioTrack.findAll({
      where: { album_id: req.params.albumId },
      order: [['track_number', 'ASC']]
    });
    res.json({ success: true, data: tracks });
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
    const tracks = await VideoTrack.findAll({
      where: { album_id: req.params.albumId },
      order: [['track_number', 'ASC']]
    });
    res.json({ success: true, data: tracks });
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

