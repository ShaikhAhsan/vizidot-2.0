# Music Platform Database Setup

## Issue
Your IP address changed from `31.187.78.19` to `31.187.78.20`, so the database connection is being blocked.

## Solution Options

### Option 1: Enable the new IP address in MySQL
1. Access your MySQL server
2. Run this SQL command to allow the new IP:
```sql
GRANT ALL PRIVILEGES ON dbvwnuu5gdchot.* TO 'u84b1oa3bdbvu'@'31.187.78.20' IDENTIFIED BY 'oi_-DR!b1GCh2qsip4';
FLUSH PRIVILEGES;
```

### Option 2: Run SQL file manually
1. Access your database through phpMyAdmin, MySQL Workbench, or any MySQL client
2. Select the database: `dbvwnuu5gdchot`
3. Execute the SQL file: `backend/scripts/createMusicPlatformTables.sql`

### Option 3: Use the backend server (if still connected)
If the backend server is still running and connected, you can create tables through it once the IP is enabled.

## Tables to Create

The following 8 tables need to be created:

1. ✅ `artists` - Main artist information
2. ✅ `artist_brandings` - Artist branding/logo information
3. ✅ `artist_shops` - Artist shop/store information
4. ✅ `albums` - Album information (audio/video)
5. ✅ `audio_tracks` - Audio track files
6. ✅ `video_tracks` - Video track files
7. ✅ `album_artists` - Album-level collaborations
8. ✅ `track_artists` - Track-level collaborations

## SQL File Location
`backend/scripts/createMusicPlatformTables.sql`

## After Tables Are Created

Once the tables exist, you can:
1. Test the API endpoints at `/api/v1/music/*`
2. Access the admin panel at `http://localhost:3000/artists`
3. Create, edit, and manage artists, albums, and tracks

## Verification

After enabling the IP and creating tables, run:
```bash
cd backend
node scripts/checkTables.js
```

This will verify all tables were created successfully.

