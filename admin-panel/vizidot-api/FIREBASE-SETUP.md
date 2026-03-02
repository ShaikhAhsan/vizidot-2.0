# Firebase "Invalid JWT Signature" Fix

If you get **"Invalid JWT Signature"** or **"UNAUTHENTICATED"**, the service account key is likely revoked or rotated.

### Fix: Download a new service account key

1. Open [Firebase Console](https://console.firebase.google.com) → your project **vizidot-4b492**
2. Go to **Project settings** (gear icon) → **Service accounts**
3. Click **Generate new private key**
4. Replace the file `vizidot-4b492-firebase-adminsdk-mmzox-c3a057f143.json` with the downloaded JSON (or save it as that name)

Make sure `.env` has:
```
FIREBASE_SERVICE_ACCOUNT_PATH=./vizidot-4b492-firebase-adminsdk-mmzox-c3a057f143.json
```

Then restart the API.
