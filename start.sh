#!/bin/bash

# Start both backend and admin panel services
# Backend runs on port 8000 (hardcoded)
# Admin panel runs on port 3000 (hardcoded)

echo "🚀 Starting Vizidot 2.0 Services..."
echo "📡 Backend will run on: http://localhost:8000"
echo "🎨 Admin Panel will run on: http://localhost:3000"
echo ""

# Ensure dependencies are installed
echo "Checking dependencies..."
if [ ! -d "vizidot-api/node_modules" ]; then
  echo "Installing backend dependencies..."
  (cd vizidot-api && npm install)
fi
if [ ! -d "vizidot-admin-panel/node_modules" ]; then
  echo "Installing admin panel dependencies..."
  (cd vizidot-admin-panel && npm install)
fi
if [ ! -f "vizidot-admin-panel/.env" ] && [ -f "vizidot-admin-panel/.env.example" ]; then
  echo "Creating vizidot-admin-panel/.env from .env.example (so http://localhost:3000 can load)"
  cp vizidot-admin-panel/.env.example vizidot-admin-panel/.env
fi
echo ""

# Start backend in background
echo "Starting backend server..."
cd vizidot-api
npm run dev &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 2

# Start admin panel in background
echo "Starting admin panel..."
cd vizidot-admin-panel
npm start &
ADMIN_PID=$!
cd ..

echo ""
echo "✅ Both services are starting..."
echo "Backend PID: $BACKEND_PID"
echo "Admin Panel PID: $ADMIN_PID"
echo ""
echo "Press Ctrl+C to stop both services"

# Wait for user interrupt
trap "kill $BACKEND_PID $ADMIN_PID 2>/dev/null; exit" INT TERM
wait

