const express = require('express');
const router = express.Router();
const { upload, processImage, deleteFile, getFileUrl } = require('../services/imageUploadService');
const { User } = require('../models');

// Custom authentication middleware for uploads
const authenticateUpload = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Access token required'
      });
    }

    // Development mode: bypass Firebase authentication for demo token
    if (process.env.NODE_ENV === 'development' && token === 'demo-token-123') {
      // Create or find a demo admin user
      let user = await User.findOne({
        where: { email: 'admin@demo.com' }
      });

      if (!user) {
        // Create demo admin user
        user = await User.create({
          email: 'admin@demo.com',
          first_name: 'Demo',
          last_name: 'Admin',
          firebase_uid: 'demo-admin-uid',
          user_type: 'admin',
          is_active: true,
          is_verified: true
        });
      }

      req.user = user;
      req.firebaseUser = { uid: 'demo-admin-uid' };
      return next();
    }

    // For production, use Firebase authentication
    const { FirebaseAuthService } = require('../services/firebaseAuth');
    const firebaseUser = await FirebaseAuthService.getUserFromToken(token);
    req.user = firebaseUser;
    req.firebaseUser = firebaseUser;
    next();
  } catch (error) {
    console.error('Upload auth middleware error:', error);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
};

// Upload single image
router.post('/image', authenticateUpload, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No image file provided'
      });
    }

    const processedImage = await processImage(req.file);
    
    res.json({
      success: true,
      data: {
        id: processedImage.filename,
        original: processedImage.original,
        thumbnail: processedImage.thumbnail,
        url: getFileUrl(processedImage.original),
        thumbnailUrl: getFileUrl(processedImage.thumbnail),
        size: processedImage.size,
        mimetype: processedImage.mimetype
      }
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload image'
    });
  }
});

// Upload multiple images
router.post('/images', authenticateUpload, upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No image files provided'
      });
    }

    const processedImages = await Promise.all(
      req.files.map(file => processImage(file))
    );

    const responseData = processedImages.map(img => ({
      id: img.filename,
      original: img.original,
      thumbnail: img.thumbnail,
      url: getFileUrl(img.original),
      thumbnailUrl: getFileUrl(img.thumbnail),
      size: img.size,
      mimetype: img.mimetype
    }));

    res.json({
      success: true,
      data: responseData
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload images'
    });
  }
});

// Delete image
router.delete('/image/:filename', authenticateUpload, async (req, res) => {
  try {
    const { filename } = req.params;
    
    // Delete original image
    await deleteFile(`products/${filename}`);
    
    // Delete thumbnail
    await deleteFile(`products/thumbs/thumb-${filename}`);
    
    res.json({
      success: true,
      message: 'Image deleted successfully'
    });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete image'
    });
  }
});

module.exports = router;
