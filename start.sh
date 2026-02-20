#!/bin/bash

# Start App API only (port 8000)

echo "🚀 Starting Vizidot 2.0 App API..."
echo "📡 App API: http://localhost:8000"
echo ""

# Ensure dependencies are installed
echo "Checking dependencies..."
if [ ! -d "app-api/node_modules" ]; then
  echo "Installing App API dependencies..."
  (cd app-api && npm install)
fi
echo ""

# Start App API in background
echo "Starting App API server..."
cd app-api
npm run dev &
BACKEND_PID=$!
cd ..

echo ""
echo "✅ App API is starting (PID: $BACKEND_PID)"
echo "Press Ctrl+C to stop"

trap "kill $BACKEND_PID 2>/dev/null; exit" INT TERM
wait
