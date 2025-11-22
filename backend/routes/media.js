const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { authenticateToken, requireSystemAdmin } = require('../middleware/authWithRoles');
const { Album, AudioTrack, VideoTrack } = require('../models');
const { uploadToGCS, isGCSAvailable } = require('../services/googleCloudStorage');

// Configure multer for media files (audio/video)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac',
    'video/mp4', 'video/mpeg', 'video/quicktime', 'video/x-msvideo', 'video/webm'
  ];
  
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only audio and video files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB limit for media files
  }
});

// Apply authentication and admin role to all routes
router.use(authenticateToken);
router.use(requireSystemAdmin);

// Bulk upload media files for an album
router.post('/albums/:albumId/media', upload.array('files', 20), async (req, res) => {
  try {
    const { albumId } = req.params;
    const { type } = req.query; // 'audio' or 'video'
    
    if (!type || !['audio', 'video'].includes(type)) {
      return res.status(400).json({
        success: false,
        error: 'Type parameter is required and must be "audio" or "video"'
      });
    }

    // Verify album exists
    const album = await Album.findByPk(albumId);
    if (!album) {
      return res.status(404).json({
        success: false,
        error: 'Album not found'
      });
    }

    // Verify album type matches
    if (album.album_type !== type) {
      return res.status(400).json({
        success: false,
        error: `Album type is "${album.album_type}", but trying to upload "${type}" files`
      });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No files provided'
      });
    }

    // Get current track count to assign track numbers
    const existingTracks = type === 'audio'
      ? await AudioTrack.count({ where: { album_id: albumId } })
      : await VideoTrack.count({ where: { album_id: albumId } });
    
    let startTrackNumber = existingTracks + 1;

    const uploadedTracks = [];

    for (const file of req.files) {
      try {
        // Extract filename without extension for default title
        const filenameWithoutExt = path.basename(file.originalname, path.extname(file.originalname));
        
        // Upload to Firebase Storage
        let mediaUrl = null;
        if (isGCSAvailable()) {
          const folder = type === 'audio' ? 'audio-tracks' : 'video-tracks';
          const uniqueFileName = `${uuidv4()}-${Date.now()}${path.extname(file.originalname)}`;
          
          const uploadResult = await uploadToGCS(
            file.buffer,
            uniqueFileName,
            folder,
            file.mimetype
          );
          
          mediaUrl = uploadResult.url;
        } else {
          return res.status(500).json({
            success: false,
            error: 'File storage is not configured'
          });
        }

        // Create track record
        const trackData = {
          album_id: albumId,
          title: filenameWithoutExt, // Use filename as default title
          track_number: startTrackNumber++,
          [type === 'audio' ? 'audio_url' : 'video_url']: mediaUrl
        };

        const track = type === 'audio'
          ? await AudioTrack.create(trackData)
          : await VideoTrack.create(trackData);

        uploadedTracks.push(track);
      } catch (fileError) {
        console.error(`Error processing file ${file.originalname}:`, fileError);
        // Continue with other files even if one fails
      }
    }

    res.status(201).json({
      success: true,
      data: uploadedTracks,
      message: `Successfully uploaded ${uploadedTracks.length} ${type} track(s)`
    });
  } catch (error) {
    console.error('Bulk upload error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to upload media files'
    });
  }
});

module.exports = router;

