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
    // Detect image format - preserve PNG for transparency, use JPEG for others
    const isPNG = mimetype === 'image/png' || path.extname(originalFileName).toLowerCase() === '.png';
    const isWebP = mimetype === 'image/webp' || path.extname(originalFileName).toLowerCase() === '.webp';
    
    // Determine output format and content type
    let outputFormat = 'jpeg';
    let contentType = 'image/jpeg';
    let outputOptions = { quality: 90 };
    
    if (isPNG) {
      outputFormat = 'png';
      contentType = 'image/png';
      outputOptions = { compressionLevel: 9 }; // PNG compression
    } else if (isWebP) {
      outputFormat = 'webp';
      contentType = 'image/webp';
      outputOptions = { quality: 90 };
    }

    // Create sharp instance with format detection
    let sharpInstance = sharp(fileBuffer);
    
    // Resize main image to 1000x1000px
    const resizeOptions = {
      fit: 'inside',
      withoutEnlargement: false
    };
    
    // For PNG, preserve transparency by using a transparent background
    if (isPNG) {
      resizeOptions.background = { r: 0, g: 0, b: 0, alpha: 0 }; // Transparent background
    }
    
    let resizedSharp = sharpInstance
      .resize(1000, 1000, resizeOptions);
    
    // Apply format-specific options
    if (isPNG) {
      resizedSharp = resizedSharp.png(outputOptions);
    } else if (isWebP) {
      resizedSharp = resizedSharp.webp(outputOptions);
    } else {
      resizedSharp = resizedSharp.jpeg(outputOptions);
    }
    
    const resizedBuffer = await resizedSharp.toBuffer();

    // Generate thumbnail (300x300px)
    // For thumbnails, preserve PNG format if original is PNG to maintain transparency
    // Use 'contain' for PNG to preserve full image with transparency, 'cover' for others
    const thumbnailResizeOptions = isPNG 
      ? {
          fit: 'contain', // Preserve full image with transparency
          background: { r: 0, g: 0, b: 0, alpha: 0 } // Transparent background
        }
      : {
          fit: 'cover',
          position: 'center'
        };
    
    let thumbnailSharp = sharp(fileBuffer)
      .resize(300, 300, thumbnailResizeOptions);
    
    if (isPNG) {
      thumbnailSharp = thumbnailSharp.png({ compressionLevel: 9 });
    } else if (isWebP) {
      thumbnailSharp = thumbnailSharp.webp({ quality: 80 });
    } else {
      thumbnailSharp = thumbnailSharp.jpeg({ quality: 80 });
    }
    
    const thumbnailBuffer = await thumbnailSharp.toBuffer();

    // Determine file extension for upload
    const fileExt = isPNG ? '.png' : isWebP ? '.webp' : '.jpg';
    const thumbnailExt = isPNG ? '.png' : isWebP ? '.webp' : '.jpg';

    // Upload original (resized)
    const originalUpload = await uploadToGCS(resizedBuffer, originalFileName.replace(path.extname(originalFileName), fileExt), folder, contentType);
    
    // Upload thumbnail
    const thumbnailFileName = `thumb-${path.basename(originalUpload.fileName).replace(fileExt, thumbnailExt)}`;
    const thumbnailUpload = await uploadToGCS(thumbnailBuffer, thumbnailFileName, `${folder}/thumbs`, contentType);

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

