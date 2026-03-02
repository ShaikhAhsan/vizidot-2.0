# Send Push Notification (Firebase Cloud Function)

This function sends FCM push notifications from Firebase’s environment, so you don’t need Firebase Admin credentials or correct server time on your own API.

## Deploy

1. **Firebase CLI**  
   From the **repo root** (where `firebase.json` and `.firebaserc` are):
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase use vizidot-4b492   # or your project
   ```

2. **Install function dependencies and deploy**  
   From the **repo root**:
   ```bash
   cd functions && npm install && cd ..
   npx firebase deploy --only functions
   ```
   (Or use `npm run deploy:functions` from the root; ensure `functions/node_modules` exists by running `npm install` in `functions` first.)
   Copy the **URL** shown for `sendPushNotification` (e.g. `https://us-central1-vizidot-4b492.cloudfunctions.net/sendPushNotification`).

## Use from your API

In your Node API (e.g. Coolify env), set:

- `FIREBASE_SEND_PUSH_FUNCTION_URL` = the function URL from the deploy step  

When this is set, `sendPushNotification()` in your API will **POST to this function** instead of using Firebase Admin on the server. No secret is required; protect the function URL (e.g. allow only your API via IAM or keep the URL private). Notification history is still written by your API to `push_notification_log` using the function’s response.

## Request format (from your API to the function)

`POST` with JSON body:

- `title` (string) – notification title  
- `message` (string) – body  
- `fcmTokens` (string[]) – device tokens  
- `data` (object, optional) – custom key-value (values stringified)  
- `imageUrl` (string, optional)

The function returns: `{ success, successCount, failureCount, total, errors? }`.
