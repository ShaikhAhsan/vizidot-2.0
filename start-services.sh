#!/bin/bash

# Script to start both backend and admin panel services
# This script will try to find Node.js and start both services

set -e

echo "🔍 Looking for Node.js..."

# Try to find node in common locations
NODE_PATH=""
if command -v node &> /dev/null; then
    NODE_PATH=$(command -v node)
elif [ -f "/usr/local/bin/node" ]; then
    NODE_PATH="/usr/local/bin/node"
elif [ -f "/opt/homebrew/bin/node" ]; then
    NODE_PATH="/opt/homebrew/bin/node"
elif [ -d "$HOME/.nvm" ]; then
    source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
    NODE_PATH=$(command -v node 2>/dev/null || echo "")
fi

if [ -z "$NODE_PATH" ]; then
    echo "❌ Node.js not found. Please install Node.js first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

echo "✅ Found Node.js at: $NODE_PATH"
$NODE_PATH --version

# Get npm path
NPM_PATH=$(dirname "$NODE_PATH")/npm
if [ ! -f "$NPM_PATH" ]; then
    NPM_PATH=$(command -v npm 2>/dev/null || echo "npm")
fi

echo ""
echo "📦 Checking dependencies..."

# Check and install backend dependencies
cd "$(dirname "$0")/backend"
if [ ! -d "node_modules" ]; then
    echo "Installing backend dependencies..."
    $NPM_PATH install
fi

# Check and install admin panel dependencies
cd "../admin-panel"
if [ ! -d "node_modules" ]; then
    echo "Installing admin panel dependencies..."
    $NPM_PATH install
fi

cd ..

echo ""
echo "🚀 Starting services..."
echo "📡 Backend will run on: http://localhost:8000"
echo "🎨 Admin Panel will run on: http://localhost:3000"
echo ""

# Start backend
cd backend
$NPM_PATH run dev > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend started (PID: $BACKEND_PID)"

# Wait a moment
sleep 3

# Start admin panel
cd ../admin-panel
PORT=3000 $NPM_PATH start > ../admin.log 2>&1 &
ADMIN_PID=$!
echo "Admin Panel started (PID: $ADMIN_PID)"

cd ..

echo ""
echo "✅ Both services are starting..."
echo "Backend PID: $BACKEND_PID"
echo "Admin Panel PID: $ADMIN_PID"
echo ""
echo "Logs:"
echo "  Backend: tail -f backend.log"
echo "  Admin: tail -f admin.log"
echo ""
echo "To stop services: kill $BACKEND_PID $ADMIN_PID"
echo ""
echo "Waiting for services to be ready..."
sleep 5

# Check if services are running
if lsof -i :8000 > /dev/null 2>&1; then
    echo "✅ Backend is running on port 8000"
else
    echo "⚠️  Backend may not be running. Check backend.log"
fi

if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Admin Panel is running on port 3000"
else
    echo "⚠️  Admin Panel may not be running. Check admin.log"
fi

