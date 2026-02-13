const express = require('express');
const router = express.Router();
const path = require('path');
const { upload, processImage, deleteFile, getFileUrl } = require('../services/imageUploadService');
const { uploadImageWithThumbnail, isGCSAvailable, deleteFromGCS } = require('../services/googleCloudStorage');
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
    const FirebaseAuthService = require('../services/firebaseAuth');
    try {
      const firebaseUser = await FirebaseAuthService.getUserFromToken(token);
      req.user = firebaseUser;
      req.firebaseUser = firebaseUser;
      next();
    } catch (authError) {
      console.error('Upload auth middleware - Token verification failed:', authError.message);
      console.error('Token preview:', token.substring(0, 50) + '...');
      throw authError; // Re-throw to be caught by outer catch
    }
  } catch (error) {
    console.error('Upload auth middleware error:', error.message);
    console.error('Error stack:', error.stack);
    return res.status(401).json({
      success: false,
      error: error.message || 'Invalid or expired token'
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

    // Determine folder based on query parameter or default to 'artists'
    const folder = req.query.folder || 'artists';
    
    // Try Firebase Storage first, fallback to local storage
    if (isGCSAvailable()) {
      try {
        const fs = require('fs');
        const fileBuffer = fs.readFileSync(req.file.path);
        
        const firebaseResult = await uploadImageWithThumbnail(
          fileBuffer,
          req.file.originalname,
          folder,
          req.file.mimetype
        );
        
        // Clean up local file
        await require('fs').promises.unlink(req.file.path);
        
        return res.json({
          success: true,
          data: {
            id: path.basename(firebaseResult.original.fileName),
            original: firebaseResult.original.fileName,
            thumbnail: firebaseResult.thumbnail.fileName,
            url: firebaseResult.original.url,
            thumbnailUrl: firebaseResult.thumbnail.url,
            size: req.file.size,
            mimetype: req.file.mimetype
          }
        });
      } catch (firebaseError) {
        console.error('Firebase Storage upload failed, falling back to local storage:', firebaseError);
        // Fall through to local storage
      }
    }

    // Local storage fallback
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
      error: error.message || 'Failed to upload image'
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
