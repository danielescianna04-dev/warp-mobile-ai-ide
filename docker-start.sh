#!/bin/bash

# Warp Mobile AI IDE - Docker Environment Starter
# Avvia tutti i servizi in container Docker

echo "🐳 Starting Warp Mobile AI IDE Docker Environment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[Docker]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

print_success "Docker is running"

# Stop any existing containers
print_status "Stopping existing containers..."
docker-compose down

# Build and start services
print_status "Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check service health
print_status "Checking service health..."

# Check backend
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    print_success "✅ Backend server is healthy"
else
    print_warning "⚠️ Backend server may still be starting..."
fi

# Check Unsplash gallery
if curl -f http://localhost:5174 > /dev/null 2>&1; then
    print_success "✅ Unsplash Gallery is healthy"
else
    print_warning "⚠️ Unsplash Gallery may still be starting..."
fi

print_success "🎉 Docker environment started!"
echo ""
echo "📋 Available services:"
echo "   🔧 Backend API: http://localhost:3001"
echo "   🖼️ Unsplash Gallery: http://localhost:5174"
echo "   🛠️ Dev Environment: docker exec -it warp_dev-environment_1 bash"
echo ""
echo "📝 Useful commands:"
echo "   📊 View logs: docker-compose logs -f"
echo "   🛑 Stop all: docker-compose down"
echo "   📱 Connect from mobile: Use your Mac's IP address"
echo ""
echo "🔗 From your mobile app, connect to:"
echo "   http://$(ipconfig getifaddr en0):3001 (Backend)"
echo "   http://$(ipconfig getifaddr en0):5174 (Unsplash Gallery)"