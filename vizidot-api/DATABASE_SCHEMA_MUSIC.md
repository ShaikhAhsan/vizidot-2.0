# Music Platform – Database Schema Reference

This document describes the MySQL table structures used by the music/artist API and the vizidot-app. Use it to create or alter tables so the API and app have all required fields.

---

## 1. `artists`

Used by: Artist profile (public), Artist CRUD (admin).

| Column        | Type          | Nullable | Default   | Description                |
|---------------|---------------|----------|-----------|----------------------------|
| artist_id     | INT           | NO       | AUTO_INC  | Primary key                |
| name          | VARCHAR(255)  | NO       | -         | Display name               |
| bio           | TEXT          | YES      | NULL      | Biography / description    |
| image_url     | VARCHAR(500)  | YES      | NULL      | Profile image URL          |
| shop_id       | INT           | YES      | NULL      | FK to artist_shops         |
| is_active     | TINYINT(1)    | YES      | 1         | 1 = active                 |
| is_deleted    | TINYINT(1)    | YES      | 0         | Soft delete                |
| deleted_at    | DATETIME      | YES      | NULL      | When soft-deleted          |
| created_at    | DATETIME      | YES      | -         |                            |
| updated_at    | DATETIME      | YES      | -         |                            |

**Create (if missing):**

```sql
CREATE TABLE IF NOT EXISTS artists (
  artist_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  bio TEXT,
  image_url VARCHAR(500),
  shop_id INT,
  is_active TINYINT(1) DEFAULT 1,
  is_deleted TINYINT(1) DEFAULT 0,
  deleted_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  PRIMARY KEY (artist_id),
  KEY idx_artists_shop_id (shop_id),
  KEY idx_artists_is_active_deleted (is_active, is_deleted)
);
```

---

## 2. `artist_followers` (optional – for follow counts)

Not present by default. If you add this table and implement counts in the API, the public artist profile can return real `followersCount` / `followingCount` instead of 0.

| Column      | Type     | Nullable | Description        |
|-------------|----------|----------|--------------------|
| id          | INT      | NO       | AUTO_INCREMENT PK  |
| user_id     | INT      | NO       | User following     |
| artist_id   | INT      | NO       | Artist followed    |
| created_at  | DATETIME | YES      |                    |

**Create:**

```sql
CREATE TABLE IF NOT EXISTS artist_followers (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  artist_id INT NOT NULL,
  created_at DATETIME,
  PRIMARY KEY (id),
  UNIQUE KEY uk_artist_followers_user_artist (user_id, artist_id),
  KEY idx_artist_followers_artist (artist_id)
);
```

After creating `artist_followers`, you can:

- In the artist profile API: count rows where `artist_id = :id` → `followersCount`.
- “Following” count for an artist is optional (e.g. count of artists that this artist “follows” if you add that relation later).

---

## 3. `albums`

| Column                  | Type           | Nullable | Description              |
|-------------------------|----------------|----------|--------------------------|
| album_id                | INT            | NO       | PK, AUTO_INCREMENT       |
| artist_id               | INT            | NO       | FK artists               |
| branding_id             | INT            | YES      | FK artist_brandings      |
| title                   | VARCHAR(255)   | NO       |                          |
| description             | TEXT           | YES      |                          |
| album_type              | ENUM('audio','video') | NO |                          |
| release_date            | DATE           | YES      |                          |
| cover_image_url         | VARCHAR(500)   | YES      | Used in app for covers   |
| default_track_thumbnail | VARCHAR(500)   | YES      | Fallback for track art   |
| is_active               | TINYINT(1)     | YES      | Default 1                |
| is_deleted              | TINYINT(1)     | YES      | Default 0                |
| deleted_at              | DATETIME       | YES      |                          |
| created_at, updated_at  | DATETIME       | YES      |                          |

---

## 4. `audio_tracks`

| Column        | Type          | Nullable | Description           |
|---------------|---------------|----------|-----------------------|
| audio_id      | INT           | NO       | PK, AUTO_INCREMENT    |
| album_id      | INT           | NO       | FK albums             |
| title         | VARCHAR(255)  | NO       |                       |
| duration      | INT           | YES      | Duration in seconds   |
| audio_url     | VARCHAR(500)  | YES      | Playback URL          |
| thumbnail_url | VARCHAR(500)  | YES      | Track/album art       |
| track_number  | INT           | YES      | Default 1             |
| is_deleted    | TINYINT(1)    | YES      | Default 0             |
| deleted_at    | DATETIME      | YES      |                       |
| created_at, updated_at | DATETIME | YES      |                       |

---

## 5. `artist_shops`

| Column      | Type          | Nullable | Description   |
|-------------|---------------|----------|---------------|
| shop_id     | INT           | NO       | PK            |
| artist_id   | INT           | YES      |               |
| branding_id | INT           | YES      |               |
| shop_name   | VARCHAR(255)  | NO       |               |
| shop_url    | VARCHAR(500)  | NO       |               |
| description | TEXT          | YES      |               |
| is_active   | TINYINT(1)    | YES      |               |
| is_deleted  | TINYINT(1)    | YES      |               |
| deleted_at  | DATETIME      | YES      |               |
| created_at, updated_at | DATETIME | YES      |               |

---

## 6. Other music tables (reference)

- **artist_brandings** – brandings for artists.
- **album_artists** – many-to-many album ↔ artist.
- **track_artists** – track ↔ artist (audio/video).
- **branding_artists**, **shop_artists** – junction tables.
- **user_artists** – user ↔ artist (e.g. assigned admins).
- **video_tracks** – same idea as audio_tracks for video.

These are already defined in the Sequelize models under `vizidot-api/models/`.

---

## Summary for Artist Profile (app)

- **Artist profile API** uses: `artists`, `artist_shops`, `albums`, `audio_tracks`.
- **Follow counts**: add `artist_followers` and implement counting in the profile endpoint if you want real follower numbers; until then the API returns `followersCount: 0`, `followingCount: 0`.
- Ensure `artists.image_url`, `albums.cover_image_url`, `albums.default_track_thumbnail`, and `audio_tracks.thumbnail_url` / `audio_url` are populated for the app to show images and play audio.
