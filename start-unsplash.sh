#!/bin/bash

echo "🖼️ Starting Unsplash Gallery..."

# Check if we're in the right place
if [ ! -d "unsplash-gallery" ]; then
    echo "❌ Error: unsplash-gallery directory not found"
    echo "Current directory: $(pwd)"
    echo "Available directories:"
    ls -la
    exit 1
fi

# Navigate and start
cd unsplash-gallery

echo "✅ Found unsplash-gallery directory"
echo "📦 Installing/checking dependencies..."

# Make sure dependencies are installed
npm install

echo "🚀 Starting development server..."
npm run dev -- --port 5174 --host

echo "🌐 Unsplash Gallery should be available at:"
echo "   Local: http://localhost:5174"
echo "   Network: http://192.168.x.x:5174"