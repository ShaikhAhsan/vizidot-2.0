# Agora Live Streaming – Setup and Testing

This app uses **Agora RTC Engine** for one-to-many live streaming. The broadcaster starts a stream from the Home FAB; viewers join via the same channel (from notifications or by opening the stream).

---

## Step 1: Get Agora credentials

1. Go to [Agora Console](https://console.agora.io/).
2. Sign in or create an account.
3. Create a project (or use an existing one).
4. In the project, note:
   - **App ID** – required for the app and (optionally) the API.
   - **App Certificate** – required only if you want **token authentication** (recommended for production). Enable it in the project and copy the certificate.

---

## Step 2: Configure the Flutter app

1. In the project root (`vizidot-app/`), create or edit `.env` (do not commit real secrets).
2. Add your Agora App ID:
   ```env
   AGORA_APP_ID=your_agora_app_id_here
   ```
   If you omit this, the app uses a built-in fallback App ID (testing only).
3. Ensure `BASE_URL` points to your API when you want to use token auth:
   ```env
   BASE_URL=https://your-api-domain.com
   ```
   For local testing without tokens, you can leave `BASE_URL` as default; the app will join with an empty token (works only if the Agora project is in testing mode).

---

## Step 3: Configure the API (optional – for token auth)

If you want the app to use **RTC tokens** (recommended for production):

1. In `api/vizidot-app-api/.env`, add:
   ```env
   AGORA_APP_ID=your_agora_app_id_here
   AGORA_APP_CERTIFICATE=your_agora_app_certificate_here
   ```
   Optional: `AGORA_TOKEN_EXPIRY_SECONDS=3600` (default 1 hour).
2. Install dependencies and start the API:
   ```bash
   cd api/vizidot-app-api
   npm install
   npm run start
   ```
   The endpoint `GET /api/v1/live/rtc-token?channelName=...&role=publisher|audience&uid=0` will return a token when the certificate is set.

If you do **not** set `AGORA_APP_CERTIFICATE`, the API still responds with `token: null`; the app then uses an empty token (Agora testing mode only).

---

## Step 4: Run the app and test broadcasting

1. **Permissions**  
   On first “Go Live”, the app will request **camera** and **microphone**. Grant them (or enable in Settings if denied).

2. **Start a stream**  
   - Open the app and sign in.
   - On the Home screen, tap the **floating action button (FAB)**.
   - Allow camera/mic if prompted.
   - A new live stream is created in Firestore and you are taken to the **Broadcast** screen with your camera preview.

3. **Broadcast UI**  
   - Mute/unmute, switch camera, end call using the on-screen controls.
   - Ending the call removes the stream from Firestore and leaves the Agora channel.

---

## Step 5: Test viewing (second device or emulator)

**Option A: Same channel name (for quick test)**  
- On a second device or emulator, you need to open the **same** stream.  
- The channel is the **Firestore document ID** of the stream (e.g. `abc123xyz`).  
- Easiest: send yourself a **push notification** that includes the stream ID (e.g. “Artist started a live stream”) and tap it; the app opens that stream and joins as audience.  
- Or: in your backend/notification flow, when a stream is created, call the notify API with `notificationType: 'liveStream'` and `liveStreamId: <docId>` so followers get a push; tapping it opens the stream.

**Option B: List of live streams**  
- If you add a “Live now” list that reads from Firestore `LiveStreams` and shows each stream’s `identifier` (doc id), users can tap one to open `BroadcastPage(isBroadcaster: false, liveStream: model)`.  
- The viewer joins the same Agora channel (`liveStream.channel` = doc id) as audience.

**Manual test without a list**  
- Start a stream on Device A and note the Firestore doc id (e.g. from logs: “Live stream created with ID: xyz”).  
- On Device B, trigger navigation to `BroadcastPage` with a `LiveStreamModel` whose `identifier` and `channel` are both that doc id (e.g. from a debug button or notification payload).

---

## Step 6: Verify end-to-end

| Step | What to check |
|------|----------------|
| 1 | FAB opens broadcast screen and you see your camera. |
| 2 | Logs show “Joined channel successfully” and channel name = Firestore doc id. |
| 3 | On a second client (same channel), you see the broadcaster’s video. |
| 4 | Mute / switch camera / end call work; after end, stream is removed from Firestore. |
| 5 | If token is used: API returns a token and app logs “Using RTC token from API”. |

---

## Troubleshooting

- **“Agora App ID is empty”**  
  Set `AGORA_APP_ID` in the app’s `.env` or use the fallback (see Step 2).

- **“Waiting for remote users to join”**  
  Viewer and broadcaster must use the **exact same channel name** (the stream’s doc id). Check that `liveStream.channel` and `liveStream.identifier` match the Firestore doc.

- **Token errors (e.g. 109/110)**  
  - Ensure App Certificate is enabled in Agora Console and `AGORA_APP_CERTIFICATE` is set in the API.  
  - Ensure `AGORA_APP_ID` on the API matches the app and Agora project.  
  - Use correct `role`: `publisher` for broadcaster, `audience` for viewer.

- **Permissions**  
  See `AGORA_PERMISSIONS.md` for required Android/iOS permissions. If the app crashes on start, consider lazy-initializing Agora only when entering the live flow (see `CRASH_DIAGNOSIS.md`).

- **Firestore**  
  New streams get a unique channel per stream (channel = Firestore doc id). Old streams created before this may have `channel` = user uid; those still work but one user can only have one active channel at a time.

---

## Summary

1. Get **App ID** (and optionally **App Certificate**) from Agora Console.  
2. Set **AGORA_APP_ID** in the Flutter app’s `.env`.  
3. Optionally set **AGORA_APP_ID** and **AGORA_APP_CERTIFICATE** in the API for token auth.  
4. Run the app, tap FAB to go live, then join the same stream from another client (e.g. via notification or a “Live now” list) to test viewing.
