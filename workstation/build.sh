#!/bin/bash

PROJECT_ID="drape-mobile-ide"
REGION="us-central1"
IMAGE_NAME="drape-workstation"
IMAGE_TAG="latest"

echo "🏗️  Building container image..."
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/drape-repo/${IMAGE_NAME}:${IMAGE_TAG} .

echo "✅ Image built and pushed to Artifact Registry"
echo "📦 Image: ${REGION}-docker.pkg.dev/${PROJECT_ID}/drape-repo/${IMAGE_NAME}:${IMAGE_TAG}"
