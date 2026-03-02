#!/bin/bash
# Check if API (8000) and Admin panel (3000) are running.
# Run this after ./start.sh to verify both services.

API_URL="${1:-http://localhost:8000}"
ADMIN_URL="${2:-http://localhost:3000}"

echo "Checking..."
echo "  API:        $API_URL/health"
echo "  Admin:      $ADMIN_URL/"
echo ""

api_ok=0
admin_ok=0

if curl -sf --connect-timeout 3 "${API_URL}/health" >/dev/null; then
  echo "  API (8000):  OK"
  api_ok=1
else
  echo "  API (8000):  NOT RUNNING or unreachable"
fi

if curl -sf --connect-timeout 3 -o /dev/null -w "%{http_code}" "$ADMIN_URL/" | grep -qE '^[23]'; then
  echo "  Admin (3000): OK"
  admin_ok=1
else
  echo "  Admin (3000): NOT RUNNING or unreachable"
fi

echo ""
if [ $api_ok -eq 1 ] && [ $admin_ok -eq 1 ]; then
  echo "Both services are running."
  exit 0
else
  echo "Start services with: ./start.sh"
  exit 1
fi
