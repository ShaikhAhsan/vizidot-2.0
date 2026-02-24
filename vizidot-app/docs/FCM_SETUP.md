# FCM (Firebase Cloud Messaging) Setup

## API check

Device API is mounted at `/api/v1/device`. Health check (no auth):

```bash
curl -s http://localhost:8000/api/v1/device/health
# → {"success":true,"service":"device","message":"Device API is running"}
```

Register and logout require a valid Firebase ID token in the `Authorization: Bearer <token>` header.

---

## iOS

1. **Xcode**: Enable **Push Notifications** for the Runner target:
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Select the **Runner** target → **Signing & Capabilities**.
   - Click **+ Capability** and add **Push Notifications**.

2. **Done in project**:
   - `Info.plist`: `UIBackgroundModes` includes `remote-notification`.
   - `AppDelegate.swift`: calls `application.registerForRemoteNotifications()` so the app receives an APNs token; Firebase uses it to issue the FCM token.

3. **Firebase Console**: Upload your APNs key (or certificate) under Project Settings → Cloud Messaging → Apple app configuration.

---

## Android

1. **Done in project**:
   - `AndroidManifest.xml`: `POST_NOTIFICATIONS` permission (required for Android 13+).
   - App requests notification permission at runtime before getting the FCM token (in `DeviceRegistrationService.getFcmToken()`).

2. **Firebase**: Ensure `google-services.json` is in `android/app/` and the app is registered in the Firebase project.

---

## Flutter (Firebase Messaging SDK)

- **Permission**: `DeviceRegistrationService.getFcmToken()` uses Firebase Messaging’s `requestPermission()` (iOS dialog; Android status) and, on Android, `permission_handler` for `Permission.notification` (Android 13+).
- **Token**: `FirebaseMessaging.instance.getToken()` returns the FCM token, which is sent to the backend on login and on token refresh.
- **Registration**: After login (and when the app opens with an existing session), the app calls `POST /api/v1/device/register` with `device_id`, `platform`, and `fcm_token`.
- **Logout**: Before sign-out, the app calls `POST /api/v1/device/logout` so the backend marks the device as inactive.
