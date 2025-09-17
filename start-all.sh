#!/bin/bash

# Warp Mobile AI IDE - Start All Services Script
# Avvia backend Node.js, frontend React e Flutter development server

echo "🚀 Starting Warp Mobile AI IDE Development Environment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Start backend server
print_status "Starting backend server on port 3001..."
cd backend
if [ -f "package.json" ]; then
    npm start > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    print_success "Backend server started (PID: $BACKEND_PID)"
else
    print_error "Backend package.json not found"
    exit 1
fi

# Go back to root
cd ..

# Start Unsplash Gallery React app
print_status "Starting Unsplash Gallery on port 5174..."
cd unsplash-gallery
if [ -f "package.json" ]; then
    npm run dev -- --port 5174 > ../logs/unsplash.log 2>&1 &
    REACT_PID=$!
    print_success "Unsplash Gallery started (PID: $REACT_PID)"
else
    print_warning "Unsplash Gallery not found - skipping"
fi

# Go back to root
cd ..

# Create logs directory if it doesn't exist
mkdir -p logs

# Save PIDs for cleanup
echo $BACKEND_PID > logs/backend.pid
echo $REACT_PID > logs/react.pid

print_success "🎉 All services started!"
echo ""
echo "📋 Services running:"
echo "   🔧 Backend: http://localhost:3001"
echo "   🖼️ Unsplash Gallery: http://localhost:5174"
echo ""
echo "📝 Logs:"
echo "   Backend: logs/backend.log"
echo "   React: logs/unsplash.log"
echo ""
echo "🛑 To stop all services, run: ./stop-all.sh"
echo "💡 To view logs: tail -f logs/backend.log"