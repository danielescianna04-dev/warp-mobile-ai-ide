#!/bin/bash
set -e

echo "🚀 Starting Docker build and push process in CloudShell..."

# Configuration
AWS_REGION="eu-north-1"
AWS_ACCOUNT_ID="703686967361"
ECR_REPOSITORY="warp-mobile-ai-ide"
IMAGE_TAG="latest"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "📋 Configuration:"
echo "  AWS Region: $AWS_REGION"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  ECR Repository: $ECR_REPOSITORY"
echo "  ECR URI: $ECR_URI"

# Step 1: Extract the build package
echo ""
echo "📦 Step 1: Extracting build package..."
if [ -f "docker-build-package.tar.gz" ]; then
    tar -xzf docker-build-package.tar.gz
    echo "✅ Package extracted successfully"
else
    echo "❌ Build package not found. Please upload docker-build-package.tar.gz first."
    exit 1
fi

# Step 2: Login to ECR
echo ""
echo "🔑 Step 2: Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI
echo "✅ ECR login successful"

# Step 3: Build the Docker image
echo ""
echo "🔨 Step 3: Building Docker image..."
echo "Using Dockerfile.production..."
docker build -f Dockerfile.production -t $ECR_REPOSITORY:$IMAGE_TAG .

# Step 4: Tag the image for ECR
echo ""
echo "🏷️ Step 4: Tagging image for ECR..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI:$IMAGE_TAG
echo "✅ Image tagged: $ECR_URI:$IMAGE_TAG"

# Step 5: Push to ECR
echo ""
echo "📤 Step 5: Pushing image to ECR..."
docker push $ECR_URI:$IMAGE_TAG
echo "✅ Image pushed successfully!"

# Step 6: Verify the image
echo ""
echo "🔍 Step 6: Verifying image in ECR..."
aws ecr describe-images --repository-name $ECR_REPOSITORY --region $AWS_REGION --image-ids imageTag=$IMAGE_TAG

echo ""
echo "🎉 Docker build and push completed successfully!"
echo "📍 Image location: $ECR_URI:$IMAGE_TAG"
echo ""
echo "🚀 Your ECS service will now be able to pull and run this image!"
echo "💡 The Lambda function will automatically scale the ECS service when needed."