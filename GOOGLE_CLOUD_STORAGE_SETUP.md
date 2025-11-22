# Google Cloud Storage Setup Guide

## Overview
The image upload system now supports Google Cloud Storage (GCS) with automatic fallback to local storage if GCS is not configured.

## Setup Steps

### 1. Create a Google Cloud Storage Bucket

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Cloud Storage** > **Buckets**
3. Click **Create Bucket**
4. Name your bucket (e.g., `vizidot-uploads`)
5. Choose a location type and region
6. Set access control to **Uniform**
7. Click **Create**

### 2. Create a Service Account

1. Go to **IAM & Admin** > **Service Accounts**
2. Click **Create Service Account**
3. Enter a name (e.g., `vizidot-storage`)
4. Click **Create and Continue**
5. Grant role: **Storage Admin** (or **Storage Object Admin** for more restricted access)
6. Click **Continue** then **Done**

### 3. Create and Download Service Account Key

1. Click on the service account you just created
2. Go to **Keys** tab
3. Click **Add Key** > **Create new key**
4. Choose **JSON** format
5. Click **Create** - this will download a JSON file

### 4. Configure the Backend

1. **Place the service account key file** in the backend directory:
   ```
   backend/gcs-service-account-key.json
   ```

2. **Set environment variables** (optional, if you want to customize):
   ```bash
   GOOGLE_CLOUD_KEYFILE=./gcs-service-account-key.json
   GOOGLE_CLOUD_PROJECT_ID=your-project-id
   GOOGLE_CLOUD_BUCKET_NAME=vizidot-uploads
   ```

   Or create a `.env` file in the backend directory:
   ```
   GOOGLE_CLOUD_KEYFILE=./gcs-service-account-key.json
   GOOGLE_CLOUD_PROJECT_ID=your-project-id
   GOOGLE_CLOUD_BUCKET_NAME=vizidot-uploads
   ```

### 5. Make Bucket Public (for public image URLs)

1. Go to your bucket in Google Cloud Console
2. Click on **Permissions** tab
3. Click **Grant Access**
4. Add principal: `allUsers`
5. Role: **Storage Object Viewer**
6. Click **Save**

**Note:** This makes all files in the bucket publicly accessible. For production, consider using signed URLs instead.

## How It Works

### Automatic Detection
- The system automatically detects if GCS is configured
- If the service account key file exists, it uses GCS
- If not, it falls back to local storage

### Upload Process
1. Image is uploaded via `/api/v1/upload/image?folder=artists`
2. System checks if GCS is available
3. If GCS is available:
   - Image is resized and uploaded to GCS
   - Thumbnail is generated and uploaded to GCS
   - Public URLs are returned
4. If GCS is not available:
   - Image is saved locally
   - Thumbnail is generated locally
   - Local URLs are returned

### File Structure in GCS
```
bucket-name/
  ├── artists/
  │   ├── [image-files]
  │   └── thumbs/
  │       └── [thumbnail-files]
  ├── products/
  │   ├── [image-files]
  │   └── thumbs/
  │       └── [thumbnail-files]
  └── ...
```

## Testing

1. **Check if GCS is available:**
   ```bash
   # The backend will log on startup:
   # ✅ Google Cloud Storage initialized
   # OR
   # ⚠️  Google Cloud Storage key file not found. Using local storage fallback.
   ```

2. **Test upload:**
   - Go to `/artists/create` in admin panel
   - Upload an image
   - Check the console logs for GCS upload confirmation
   - Verify the image URL points to `storage.googleapis.com`

## Troubleshooting

### "Google Cloud Storage is not configured"
- Ensure the service account key file exists at `backend/gcs-service-account-key.json`
- Check file permissions
- Verify the JSON file is valid

### "Permission denied" errors
- Ensure the service account has **Storage Admin** or **Storage Object Admin** role
- Check bucket permissions

### Images not accessible publicly
- Ensure bucket has public access enabled (see step 5 above)
- Or implement signed URLs for private access

## Security Notes

- **Never commit** the service account key file to git
- Add `gcs-service-account-key.json` to `.gitignore`
- Use environment variables for sensitive configuration
- Consider using signed URLs for private images in production

## Current Status

✅ GCS integration code is ready
⚠️  **You need to provide the service account key file**

Once you place the key file at `backend/gcs-service-account-key.json`, the system will automatically use Google Cloud Storage for all image uploads.

