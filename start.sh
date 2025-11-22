#!/bin/bash

# Start both backend and admin panel services
# Backend runs on port 8000 (hardcoded)
# Admin panel runs on port 3000 (hardcoded)

echo "🚀 Starting Vizidot 2.0 Services..."
echo "📡 Backend will run on: http://localhost:8000"
echo "🎨 Admin Panel will run on: http://localhost:3000"
echo ""

# Start backend in background
echo "Starting backend server..."
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 2

# Start admin panel in background
echo "Starting admin panel..."
cd admin-panel
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

