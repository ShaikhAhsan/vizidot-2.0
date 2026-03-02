#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="${ROOT_DIR}/vizidot-api"
ADMIN_DIR="${ROOT_DIR}/vizidot-admin-panel"

# Ports: API=8000, Admin panel=3000
API_PORT=8000
ADMIN_PORT=3000

echo "=============================================="
echo "  API:         port ${API_PORT}"
echo "  Admin panel: port ${ADMIN_PORT}"
echo "  (Run ./check.sh in another terminal to verify)"
echo "=============================================="

cleanup() {
  if [ -n "$API_PID" ] && kill -0 "$API_PID" 2>/dev/null; then
    echo "Stopping API (PID: $API_PID)..."
    kill "$API_PID" 2>/dev/null || true
  fi
  exit 0
}
trap cleanup SIGINT SIGTERM

# Start API in background on port 8000
if [ -d "$API_DIR" ] && [ -f "${API_DIR}/server.js" ]; then
  echo "Starting API on port ${API_PORT}..."
  (cd "$API_DIR" && export PORT=$API_PORT && node server.js) &
  API_PID=$!
  echo "API started (PID: $API_PID)"
  sleep 2
else
  echo "API directory or server.js not found at $API_DIR"
  exit 1
fi

# Start admin panel on port 3000 (foreground)
if [ -d "$ADMIN_DIR" ]; then
  if [ -d "${ADMIN_DIR}/build" ]; then
    echo "Starting admin panel (production build) on port ${ADMIN_PORT}..."
    (cd "$ADMIN_DIR" && export PORT=$ADMIN_PORT && npx serve -s build -l $ADMIN_PORT)
  else
    echo "Starting admin panel (development) on port ${ADMIN_PORT}..."
    (cd "$ADMIN_DIR" && export PORT=$ADMIN_PORT && npm run start)
  fi
else
  echo "Admin panel directory not found at $ADMIN_DIR"
  cleanup
fi
