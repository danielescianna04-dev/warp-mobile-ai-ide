#!/bin/bash

echo "🚀 Building APP image (fast, ~30 seconds)"

gcloud builds submit \
  --tag us-central1-docker.pkg.dev/drape-mobile-ide/drape-repo/drape-workstation:latest \
  .

echo "✅ App image built!"
