# Fix: Admin Panel compile + App API port 8000

## 1. Fix admin panel "Failed to compile" (missing modules)

The errors mean `node_modules` is incomplete or corrupted. Do a clean install:

```bash
cd vizidot-admin-panel
rm -rf node_modules
npm install
npm start
```

If you prefer to keep the lockfile:

```bash
cd vizidot-admin-panel
rm -rf node_modules
npm ci
npm start
```

## 2. Fix app-api "EADDRINUSE: port 8000"

Something else is already using port 8000, so app-api can't bind. Free the port then start app-api.

**Find what's using 8000:**
```bash
lsof -i :8000
```
Or on some systems:
```bash
netstat -anv | grep 8000
```

**Kill that process** (use the PID from the second column of `lsof`):
```bash
kill <PID>
```
If it doesn't exit:
```bash
kill -9 <PID>
```

**Then start App API:**
```bash
cd app-api
npm run dev
```

## 3. Run both (after fixes)

**Terminal 1 – App API (port 8000):**
```bash
cd app-api && npm run dev
```

**Terminal 2 – Admin panel (port 3000):**
```bash
cd vizidot-admin-panel && npm start
```

Or use `./start.sh` only after you've done the admin panel `rm -rf node_modules && npm install` once, and ensured nothing else is using port 8000.
