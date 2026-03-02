# Coolify Deployment – Vizidot API

## Fix: "connect ECONNREFUSED 127.0.1.1:3306"

The hostname may resolve to `127.0.1.1` inside the Coolify container. Use the **IP address** to skip DNS:

1. **Get the Hostinger MySQL IP** – From your Mac/PC:
   ```bash
   nslookup srv1149167.hstgr.cloud
   ```
   Or use an online DNS tool. If it returns something other than `109.106.244.241`, use that IP. From your Hostinger hPanel, also check **Databases → Remote MySQL** for the server address.

2. **Add in Coolify → Environment Variables:**
   ```
   VIZIDOT_DB_HOST_IP=<the-IP-from-step-1>
   ```
   Example: `VIZIDOT_DB_HOST_IP=37.XXX.XXX.XXX` (replace with your Hostinger MySQL IP).

3. **Unlink** the Coolify MySQL: API service → Database → Unlink

4. **Redeploy** the API

---

## Why "Server is not functional"

Common causes and fixes:

---

### 1. **PORT** – Fixed in code

The API now uses `process.env.PORT || 8000`. Coolify sets `PORT` automatically. No change needed.

---

### 2. **Environment variables in Coolify**

In Coolify → your API service → **Environment Variables**, add:

| Variable | Value |
|----------|-------|
| `NODE_ENV` | `production` |
| `VIZIDOT_DB_HOST` | `srv1149167.hstgr.cloud` (**use this** – Coolify won't overwrite it) |
| `DB_FORCE_HOST` | `srv1149167.hstgr.cloud` (backup if VIZIDOT_DB_HOST not set) |
| `DB_HOST` | `srv1149167.hstgr.cloud` |
| `DB_PORT` | `3306` |
| `DB_NAME` | `u5gdchot-vizidot` |
| `DB_USER` | `api_vizidot_user` |
| `DB_PASSWORD` | Your Hostinger MySQL password |
| `DB_SSL` | `true` |
| `FIREBASE_PROJECT_ID` | `vizidot-4b492` |
| `FIREBASE_DATABASE_URL` | `https://vizidot-4b492.firebaseio.com` |
| `CORS_ORIGINS` | Your admin panel URL(s), e.g. `https://YOUR-ADMIN-PANEL-URL` |
| `JWT_SECRET` | A strong random string |

---

### 3. **Firebase credentials**

The `vizidot-4b492-firebase-adminsdk-mmzox-c3a057f143.json` file may not exist in the built image.

**Option A – Use env variable (recommended on Coolify):**

1. Set `FIREBASE_SERVICE_ACCOUNT_JSON` in Coolify (as a secret).
2. Paste the full JSON content (minified, one line).
3. Unset `FIREBASE_SERVICE_ACCOUNT_PATH` or leave it empty.

**Option B – Mount the file:**

Add the JSON file as a volume or build secret in Coolify.

---

### 4. **Hostinger MySQL – allow Coolify IP**

Hostinger MySQL must allow connections from the Coolify server:

1. Get the Coolify server IP (e.g. `109.106.244.241`).
2. In Hostinger MySQL (phpMyAdmin or Remote MySQL), add that IP to allowed hosts.
3. Create/update user and grant:

```sql
CREATE USER IF NOT EXISTS 'api_vizidot_user'@'109.106.244.241' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON `u5gdchot-vizidot`.* TO 'api_vizidot_user'@'109.106.244.241';
FLUSH PRIVILEGES;
```

(Replace `109.106.244.241` with your Coolify server IP if different.)

---

### 5. **CORS**

`CORS_ORIGINS` must include the exact URL of your admin panel, including scheme:

- `https://sk4kks0s4swsgg80cw0kcgk4.109.106.244.241.sslip.io`
- or `https://your-admin-domain.com`

Add the admin panel URL without a trailing slash.

---

### 6. **Health check**

After deploy, open:

```
https://YOUR-API-URL/health
```

This page shows DB, Firebase, and Firebase Storage status.

---

### 7. **Build/start commands (Coolify)**

- **Build:** `npm install` (or leave default)
- **Start:** `node server.js` or `npm start`
- **Base directory:** `vizidot-api` (if repo root is admin-panel)
