/**
 * Firebase Storage Service
 * Handles file uploads to Firebase Storage
 */

const admin = require('firebase-admin');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

// Initialize Firebase Storage
let bucket = null;

// Initialize Firebase Storage
const initializeFirebaseStorage = () => {
  try {
    // Check if Firebase Admin is initialized
    if (!admin.apps.length) {
      console.warn('⚠️  Firebase Admin not initialized. Using local storage fallback.');
      return false;
    }

    // Get Firebase Storage bucket
    const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'vizidot-4b492.appspot.com';
    bucket = admin.storage().bucket(bucketName);

    console.log(`✅ Firebase Storage initialized: ${bucketName}`);
    return true;
  } catch (error) {
    console.error('❌ Error initializing Firebase Storage:', error.message);
    return false;
  }
};

// Check if Firebase Storage is available
const isGCSAvailable = () => {
  if (!bucket) {
    return initializeFirebaseStorage();
  }
  return true;
};

// Upload file to Firebase Storage
const uploadToGCS = async (fileBuffer, fileName, folder = 'artists', contentType = 'image/jpeg') => {
  if (!isGCSAvailable()) {
    throw new Error('Firebase Storage is not configured');
  }

  try {
    const uniqueFileName = `${folder}/${uuidv4()}-${Date.now()}${path.extname(fileName)}`;
    const file = bucket.file(uniqueFileName);

    // Upload file
    await file.save(fileBuffer, {
      metadata: {
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      },
    });

    // Make file publicly accessible
    await file.makePublic();

    // Get public URL
    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(uniqueFileName)}?alt=media`;

    return {
      fileName: uniqueFileName,
      url: publicUrl,
      bucket: bucket.name
    };
  } catch (error) {
    console.error('Error uploading to Firebase Storage:', error);
    throw error;
  }
};

// Generate thumbnail and upload to Firebase Storage
const uploadImageWithThumbnail = async (fileBuffer, originalFileName, folder = 'artists', mimetype = 'image/jpeg') => {
  if (!isGCSAvailable()) {
    throw new Error('Firebase Storage is not configured');
  }

  try {
    // Resize main image to 1000x1000px
    const resizedBuffer = await sharp(fileBuffer)
      .resize(1000, 1000, {
        fit: 'inside',
        withoutEnlargement: false
      })
      .jpeg({ quality: 90 })
      .toBuffer();

    // Generate thumbnail (300x300px)
    const thumbnailBuffer = await sharp(fileBuffer)
      .resize(300, 300, {
        fit: 'cover',
        position: 'center'
      })
      .jpeg({ quality: 80 })
      .toBuffer();

    // Upload original (resized) - always JPEG after processing
    const originalUpload = await uploadToGCS(resizedBuffer, originalFileName, folder, 'image/jpeg');
    
    // Upload thumbnail - always JPEG
    const thumbnailFileName = `thumb-${path.basename(originalUpload.fileName)}`;
    const thumbnailUpload = await uploadToGCS(thumbnailBuffer, thumbnailFileName, `${folder}/thumbs`, 'image/jpeg');

    return {
      original: {
        fileName: originalUpload.fileName,
        url: originalUpload.url
      },
      thumbnail: {
        fileName: thumbnailUpload.fileName,
        url: thumbnailUpload.url
      }
    };
  } catch (error) {
    console.error('Error processing image with thumbnail:', error);
    throw error;
  }
};

// Delete file from Firebase Storage
const deleteFromGCS = async (fileName) => {
  if (!isGCSAvailable()) {
    throw new Error('Firebase Storage is not configured');
  }

  try {
    const file = bucket.file(fileName);
    await file.delete();
    console.log(`Deleted file from Firebase Storage: ${fileName}`);
    return true;
  } catch (error) {
    console.error('Error deleting from Firebase Storage:', error);
    throw error;
  }
};

// Get file URL
const getFileUrl = (fileName) => {
  if (!isGCSAvailable()) {
    // Fallback to local storage
    return `/uploads/${fileName}`;
  }
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fileName)}?alt=media`;
};

module.exports = {
  initializeFirebaseStorage,
  isGCSAvailable,
  uploadToGCS,
  uploadImageWithThumbnail,
  deleteFromGCS,
  getFileUrl
};

