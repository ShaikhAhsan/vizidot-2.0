# Admin Panel Deployment

## Why deployment fails with "ForbiddenError"

If you see `ForbiddenError: Forbidden` from `serve-index` / `webpack-dev-server`, the app is running the **development server** (`npm start` = webpack-dev-server) in production. The dev server is not meant for production and can throw when serving certain paths.

## Fix: Use production build + static server

**Do not use `npm start` in production.** Use the production build and serve it:

### Option A – Build then serve (recommended)

```bash
npm run build
npm run start:prod
```

`start:prod` serves the `build/` folder with SPA fallback on `PORT` (default 3000).

### Option B – Docker

From this directory:

```bash
docker build -t vizidot-admin .
docker run -p 3000:3000 -e PORT=3000 vizidot-admin
```

The Dockerfile builds the app and runs `serve -s build` (no webpack-dev-server).

### Option C – Platform (Railway, Render, etc.)

- **Build command:** `npm run build`
- **Start command:** `npm run start:prod` (or `npx serve -s build -l $PORT`)

Do **not** use `npm start` as the start command in production.
