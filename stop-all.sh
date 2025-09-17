#!/bin/bash

# Warp Mobile AI IDE - Stop All Services Script

echo "🛑 Stopping all services..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Stop backend server
if [ -f "logs/backend.pid" ]; then
    BACKEND_PID=$(cat logs/backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        print_status "Stopping backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        print_success "Backend server stopped"
    fi
    rm -f logs/backend.pid
fi

# Stop React app
if [ -f "logs/react.pid" ]; then
    REACT_PID=$(cat logs/react.pid)
    if kill -0 $REACT_PID 2>/dev/null; then
        print_status "Stopping Unsplash Gallery (PID: $REACT_PID)..."
        kill $REACT_PID
        print_success "Unsplash Gallery stopped"
    fi
    rm -f logs/react.pid
fi

# Kill any remaining processes
pkill -f "node server.js" 2>/dev/null
pkill -f "vite" 2>/dev/null
pkill -f "npm run dev" 2>/dev/null

print_success "🎉 All services stopped!"

# Clean up log files (optional)
read -p "Delete log files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf logs/
    print_success "Log files deleted"
fi