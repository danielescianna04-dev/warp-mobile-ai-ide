#!/bin/bash

# Warp Mobile AI IDE Development Scripts
# Usage: ./scripts/dev.sh <command>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

case "$1" in
  "setup")
    echo "🔧 Setting up Warp Mobile AI IDE development environment..."
    echo "📦 Getting Flutter dependencies..."
    flutter pub get
    
    echo "🏗️ Building generated files..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    echo "✅ Development environment setup complete!"
    ;;
    
  "clean")
    echo "🧹 Cleaning project..."
    flutter clean
    flutter pub get
    flutter packages pub run build_runner clean
    echo "✅ Project cleaned!"
    ;;
    
  "codegen")
    echo "🏗️ Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    echo "✅ Code generation complete!"
    ;;
    
  "test")
    echo "🧪 Running tests..."
    flutter test
    echo "✅ Tests complete!"
    ;;
    
  "lint")
    echo "🔍 Running linter..."
    flutter analyze
    echo "✅ Linting complete!"
    ;;
    
  "format")
    echo "💅 Formatting code..."
    dart format lib/ test/ --set-exit-if-changed
    echo "✅ Code formatting complete!"
    ;;
    
  "build-android")
    echo "📱 Building Android APK..."
    flutter build apk --release
    echo "✅ Android build complete! APK location: build/app/outputs/flutter-apk/"
    ;;
    
  "build-ios")
    echo "🍎 Building iOS app..."
    flutter build ios --release
    echo "✅ iOS build complete!"
    ;;
    
  "run-android")
    echo "🚀 Running on Android device..."
    flutter run --release
    ;;
    
  "run-ios")
    echo "🚀 Running on iOS device..."
    flutter run --release
    ;;
    
  "analyze")
    echo "📊 Running full project analysis..."
    echo "1. Linting..."
    flutter analyze
    echo "2. Testing..."
    flutter test
    echo "3. Checking formatting..."
    dart format lib/ test/ --set-exit-if-changed
    echo "✅ Analysis complete!"
    ;;
    
  "prepare-release")
    echo "🚀 Preparing release build..."
    echo "1. Cleaning..."
    flutter clean
    flutter pub get
    
    echo "2. Code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    echo "3. Testing..."
    flutter test
    
    echo "4. Linting..."
    flutter analyze
    
    echo "5. Building Android..."
    flutter build apk --release
    
    echo "6. Building iOS..."
    flutter build ios --release
    
    echo "✅ Release preparation complete!"
    ;;
    
  "dev-run")
    echo "🏃 Starting development server..."
    flutter run --debug --hot
    ;;
    
  "help"|*)
    echo "🚀 Warp Mobile AI IDE Development Scripts"
    echo ""
    echo "Available commands:"
    echo "  setup           - Set up development environment"
    echo "  clean           - Clean project and dependencies"
    echo "  codegen         - Run code generation"
    echo "  test            - Run all tests"
    echo "  lint            - Run linter"
    echo "  format          - Format code"
    echo "  build-android   - Build Android APK"
    echo "  build-ios       - Build iOS app"
    echo "  run-android     - Run on Android device"
    echo "  run-ios         - Run on iOS device"
    echo "  analyze         - Run full analysis (lint + test + format)"
    echo "  prepare-release - Prepare release builds"
    echo "  dev-run         - Start development server with hot reload"
    echo "  help            - Show this help message"
    echo ""
    echo "Usage: ./scripts/dev.sh <command>"
    ;;
esac