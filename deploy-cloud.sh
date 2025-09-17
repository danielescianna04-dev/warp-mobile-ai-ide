#!/bin/bash

# 🚀 Warp Mobile AI IDE - Production Cloud Deployment Script
# Deploys multi-tenant production server to Google Cloud Run

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${1:-""}
REGION=${2:-"us-central1"}
SERVICE_NAME="warp-mobile-ai-ide"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Please provide your Google Cloud Project ID${NC}"
    echo -e "${BLUE}Usage: ./deploy-cloud.sh YOUR_PROJECT_ID [region]${NC}"
    echo -e "${BLUE}Example: ./deploy-cloud.sh my-warp-project us-central1${NC}\n"
    exit 1
fi

echo -e "${BLUE}🚀 Warp Mobile AI IDE - Production Deployment${NC}"
echo -e "${BLUE}===============================================${NC}\n"
echo -e "${GREEN}📋 Configuration:${NC}"
echo -e "   Project ID: $PROJECT_ID"
echo -e "   Region: $REGION"
echo -e "   Service: $SERVICE_NAME"
echo -e "   Image: $IMAGE_NAME\n"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}📝 Please edit .env with your actual API keys before continuing${NC}"
        echo -e "${YELLOW}   Press ENTER when ready...${NC}"
        read
    else
        echo -e "${RED}❌ No .env.example found. Please create .env with your API keys${NC}"
        exit 1
    fi
fi

# Setup Google Cloud
echo -e "${BLUE}🔧 Setting up Google Cloud project...${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${BLUE}🔧 Enabling required APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build Docker image
echo -e "${BLUE}🐳 Building Docker image...${NC}"
docker build -t $IMAGE_NAME .

# Push image to Google Container Registry
echo -e "${BLUE}📤 Pushing image to Google Container Registry...${NC}"
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo -e "${BLUE}☁️  Deploying to Google Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --memory 4Gi \
    --cpu 2 \
    --concurrency 50 \
    --timeout 3600 \
    --max-instances 20 \
    --set-env-vars NODE_ENV=production \
    --set-env-vars PORT=8080

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')

echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"
echo -e "${GREEN}🔧 WebSocket URL: ${SERVICE_URL/https/wss}${NC}"
echo -e "${GREEN}📊 Cloud Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID${NC}\n"

echo -e "${BLUE}📱 Frontend Configuration:${NC}"
echo -e "Update your frontend to connect to:"
echo -e "   API_BASE_URL: $SERVICE_URL"
echo -e "   WS_BASE_URL: ${SERVICE_URL/https/wss}\n"

echo -e "${YELLOW}💡 Next Steps:${NC}"
echo -e "1. Update your frontend configuration with the URLs above"
echo -e "2. Test the deployment by accessing the service URL"
echo -e "3. Monitor logs: gcloud logs read --service=$SERVICE_NAME --region=$REGION"
echo -e "4. Scale if needed: gcloud run services update $SERVICE_NAME --region=$REGION --max-instances=20\n"

echo -e "${GREEN}✅ Your Warp Mobile AI IDE is now running in production!${NC}"
echo -e "${GREEN}🔒 Multi-tenant architecture with user isolation${NC}"
echo -e "${GREEN}🚀 Ready for global users without Docker requirements${NC}"
