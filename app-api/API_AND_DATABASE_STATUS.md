# API & Database Status

This document maps **database tables** (from `schema.sql`) to **APIs** and calls out what is missing so you can update with help.

---

## 1. Database tables (14) – all have API or internal use

| Table             | API / usage |
|-------------------|-------------|
| **artists**       | ✅ Public: `GET /api/v1/music/artists/public`, `GET /api/v1/music/artists/profile/:id`. Admin: full CRUD under `/api/v1/music/artists`. |
| **albums**        | ✅ Public: `GET /api/v1/music/albums/public`, `GET /api/v1/music/albums/profile/:id`. Admin: full CRUD under `/api/v1/music/albums`. |
| **audio_tracks**  | ✅ Admin: list/add/update/delete under `/api/v1/music/albums/:id/audio-tracks`, `PUT/DELETE /api/v1/music/audio-tracks/:id`. Included in artist & album profile. |
| **video_tracks**  | ✅ Admin: list/add/update/delete under `/api/v1/music/albums/:id/video-tracks`, `PUT/DELETE /api/v1/music/video-tracks/:id`. Included in album profile. |
| **artist_brandings** | ✅ Admin: full CRUD under `/api/v1/music/brandings`. |
| **artist_shops**  | ✅ Admin: full CRUD under `/api/v1/music/shops`. Included in artist profile. |
| **album_artists** | ✅ Admin: `GET/POST/DELETE /api/v1/music/albums/:albumId/collaborators`. |
| **branding_artists** | ✅ Used when managing brandings (many-to-many). |
| **shop_artists**   | ✅ Used when managing shops (many-to-many). |
| **track_artists** | ✅ Admin: `GET/POST/DELETE /api/v1/music/audio-tracks/:id/artists`, same for `video-tracks/:id/artists`. |
| **user_artists**  | ✅ Admin: `GET/POST /api/v1/admin/users/:id/artists`. |
| **users**         | ✅ Auth + `/api/v1/users` + admin users CRUD. |
| **roles**         | ✅ Admin: `GET /api/v1/admin/roles`. |
| **user_roles**    | ✅ Used by auth and admin (assign roles to users). |

---

## 2. Public APIs (no auth) – for the app

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/music/artists/public` | List active artists (paginated, optional search). |
| `GET /api/v1/music/artists/profile/:id` | Artist profile + albums + tracks for detail view. |
| `GET /api/v1/music/albums/public` | List active albums (paginated, optional search, albumType filter). |
| `GET /api/v1/music/albums/profile/:id` | Album detail + audio/video tracks. |

---

## 3. Optional features (implemented)

### 3.1 Artist followers

- **Table** `artist_followers`: create with `node scripts/createArtistFollowersTable.js` (see `DATABASE_SCHEMA_MUSIC.md`).
- **APIs** (auth required, any logged-in user):
  - `POST /api/v1/music/artists/:id/follow`
  - `DELETE /api/v1/music/artists/:id/follow`
- **Artist profile** `GET /api/v1/music/artists/profile/:id` returns real `followersCount` when the table exists.

### 3.2 Track artists (featuring)

- **APIs** (admin): `GET/POST/DELETE /api/v1/music/audio-tracks/:id/artists`, same for `video-tracks/:id/artists`. Body for POST: `{ "artist_id": number, "role": "Featured" }`.

---

## 4. Quick check: artist profile response vs DB

Artist profile API returns (from DB):

- **artist**: id, name, bio, **country**, **dob**, imageUrl, followersCount (0 until `artist_followers`), followingCount (0), shopId, shop (id, shopName, shopUrl).
- **albums**: id, title, coverImageUrl, artistName.
- **tracks**: id, title, durationFormatted, durationSeconds, albumArt, artistName, audioUrl, albumId.

All of these columns exist in the current schema. Only **followersCount** / **followingCount** need the optional `artist_followers` table to be real.

---

## 5. Summary

- **APIs are in place** for all 14 tables (either direct CRUD/admin or used inside existing endpoints).
- **Public app endpoints** cover: list artists, artist profile, list albums, album profile.
- **Optional features are implemented:** artist_followers (table script + follow/unfollow APIs + profile count), track-artists (GET/POST/DELETE for audio and video tracks).
