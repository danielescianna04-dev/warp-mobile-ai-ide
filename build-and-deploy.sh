#!/bin/bash

# Script per build e deploy dell'immagine Docker Flutter in AWS ECR
# Ottimizzato per CloudShell - npm install dentro Docker

set -e  # Exit on any error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Docker build and ECR deployment...${NC}"

# Configurazione AWS ECR
AWS_REGION="eu-north-1"
ECR_REPOSITORY="flutter-ecs-app"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  AWS Region: ${AWS_REGION}"
echo "  ECR Repository: ${ECR_REPOSITORY}"
echo "  ECR URI: ${ECR_URI}"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"

# Verifica file necessari
if [ ! -f "backend/package.json" ]; then
    echo -e "${RED}❌ backend/package.json not found!${NC}"
    exit 1
fi

if [ ! -f "backend/Dockerfile.minimal" ]; then
    echo -e "${RED}❌ backend/Dockerfile.minimal not found!${NC}"
    exit 1
fi

if [ ! -f "backend/ecs-server.js" ]; then
    echo -e "${RED}❌ backend/ecs-server.js not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"

# Cambia directory nel backend
cd backend

echo -e "${BLUE}🔧 Building minimal Docker image (Node.js only)...${NC}"
docker build -f Dockerfile.minimal -t flutter-ecs-app .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed!${NC}"
    echo -e "${YELLOW}💡 Check Dockerfile.minimal and package.json${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully${NC}"

echo -e "${BLUE}🔐 Logging into AWS ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ECR login successful${NC}"

echo -e "${BLUE}🏷️ Tagging image...${NC}"
docker tag flutter-ecs-app:latest ${ECR_URI}:latest

echo -e "${BLUE}📤 Pushing to ECR...${NC}"
docker push ${ECR_URI}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR push failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Image pushed to ECR successfully!${NC}"

# Verifica l'immagine in ECR
echo -e "${BLUE}🔍 Verifying image in ECR...${NC}"
aws ecr describe-images --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION} --query 'imageDetails[0].{Digest:imageDigest,Tags:imageTags,Size:imageSizeInBytes,Date:imagePushedAt}' --output table

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Update ECS service to use new image"
echo "  2. Monitor ECS service deployment"
echo "  3. Test Lambda API endpoints"

echo -e "${BLUE}🔄 Updating ECS service...${NC}"
aws ecs update-service \
    --cluster flutter-ecs-cluster \
    --service flutter-ecs-service \
    --force-new-deployment \
    --region ${AWS_REGION}

echo -e "${GREEN}✅ ECS service deployment triggered${NC}"
echo -e "${BLUE}🔄 ECS service will pull the new image automatically${NC}"