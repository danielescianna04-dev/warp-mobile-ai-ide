#!/bin/bash

echo "🏗️  Building BASE image with essential languages (this takes ~15 minutes, but only once!)"
echo "Languages: Node.js, Python, Go, Rust, Ruby, PHP, Java, C#/.NET, Flutter/Dart, Android SDK, Docker, Terraform"

gcloud builds submit \
  --config cloudbuild-base.yaml \
  --timeout=30m \
  .

echo "✅ Base image built! Now you can build the app image in ~30 seconds"
