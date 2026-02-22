# Deploying the App API

## Database connection (ECONNREFUSED 127.0.0.1 / 127.0.1.1:3306)

If you see `connect ECONNREFUSED 127.0.0.1:3306` or `127.0.1.1:3306` even though `DB_HOST` is set to your remote host (e.g. `srv1149167.hstgr.cloud`), the hostname is **resolving to loopback** inside the container (common with **Coolify**, Docker, and some hosters).

### Fix for Coolify / Docker (use IP instead of hostname)

1. **Find the real IP** of your MySQL server:
   - From your **Hostinger** (or hoster) panel: use the IP shown for the database server, or
   - From your laptop / any machine **outside** the container: run  
     `ping srv1149167.hstgr.cloud`  
     or  
     `nslookup srv1149167.hstgr.cloud`  
     and use the IP shown (e.g. `109.106.244.241` or similar).

2. **Set `DB_HOST_IP`** in Coolify (or your platform) to that **IP address** (numbers only). The app will then connect to that IP and skip hostname resolution.
   - In Coolify: your app → **Environment** → add variable:
     - Name: `DB_HOST_IP`  
     - Value: `YOUR_MYSQL_SERVER_IP` (e.g. `109.106.244.241`)

3. Keep `DB_HOST` as the hostname if you like (used for logs); the connection uses `DB_HOST_IP` when set.

4. **Redeploy** the app so the new env is applied.

### General fix (all platforms)

1. Set in your deployment **Environment**:
   - `DB_HOST` = MySQL hostname (e.g. `srv1149167.hstgr.cloud`) or, if resolution is wrong, use **IP** as `DB_HOST` or set `DB_HOST_IP` to the IP
   - `DB_PORT` = `3306`
   - `DB_NAME`, `DB_USER`, `DB_PASSWORD` = your credentials
   - `NODE_ENV` = `production` (recommended)

2. Call `GET /health` to confirm: `db.hostSet` and `db.hostIsRemote` should be true.

3. Redeploy after changing env vars.

### Example (Coolify + Hostinger)

- `DB_HOST` = `srv1149167.hstgr.cloud`
- **`DB_HOST_IP`** = `1.2.3.4` ← replace with the actual IP of `srv1149167.hstgr.cloud` (from panel or `ping`/`nslookup`)
- `DB_NAME` = `u5gdchot-vizidot`
- `DB_USER` = `api_vizidot_user`
- `DB_PASSWORD` = your password
- `NODE_ENV` = `production`
