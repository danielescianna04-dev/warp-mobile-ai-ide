#!/bin/bash

# Deploy completo Flutter ECS tramite AWS CodeBuild
# Nessuna necessità di Docker locale

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting AWS CodeBuild deployment...${NC}"

# Configurazione
AWS_REGION="eu-north-1"
ECR_REPOSITORY="flutter-ecs-app"
BUCKET_NAME="flutter-ecs-codebuild-1758753635"
PROJECT_NAME="flutter-ecs-build"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo "  ECR Repository: $ECR_REPOSITORY"
echo "  S3 Bucket: $BUCKET_NAME"

echo -e "${BLUE}🔍 Checking if CodeBuild project exists...${NC}"
if aws codebuild batch-get-projects --names $PROJECT_NAME --region $AWS_REGION >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ CodeBuild project exists, deleting...${NC}"
    aws codebuild delete-project --name $PROJECT_NAME --region $AWS_REGION
fi

echo -e "${BLUE}🏗️ Creating CodeBuild project...${NC}"

# Create IAM service role if it doesn't exist
ROLE_NAME="CodeBuildServiceRole-flutter-ecs"
if ! aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
    echo -e "${BLUE}👤 Creating IAM role for CodeBuild...${NC}"
    
    # Trust policy for CodeBuild
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json

    # Attach necessary policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

    rm trust-policy.json
    
    echo -e "${GREEN}✅ IAM role created${NC}"
    
    # Wait for role to be available
    echo -e "${YELLOW}⏳ Waiting for role to be available...${NC}"
    sleep 10
fi

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

# Create CodeBuild project
cat > codebuild-project.json << EOF
{
    "name": "$PROJECT_NAME",
    "description": "Build and deploy Flutter ECS Docker image",
    "source": {
        "type": "S3",
        "location": "$BUCKET_NAME/codebuild-source.zip"
    },
    "artifacts": {
        "type": "NO_ARTIFACTS"
    },
    "environment": {
        "type": "LINUX_CONTAINER",
        "image": "aws/codebuild/standard:7.0",
        "computeType": "BUILD_GENERAL1_MEDIUM",
        "privilegedMode": true
    },
    "serviceRole": "$ROLE_ARN"
}
EOF

aws codebuild create-project \
    --cli-input-json file://codebuild-project.json \
    --region $AWS_REGION

rm codebuild-project.json

echo -e "${GREEN}✅ CodeBuild project created${NC}"

echo -e "${BLUE}🚀 Starting build...${NC}"
BUILD_ID=$(aws codebuild start-build \
    --project-name $PROJECT_NAME \
    --region $AWS_REGION \
    --query 'build.id' \
    --output text)

echo -e "${YELLOW}📊 Build ID: $BUILD_ID${NC}"
echo -e "${BLUE}📺 You can monitor the build at:${NC}"
echo "https://eu-north-1.console.aws.amazon.com/codesuite/codebuild/projects/$PROJECT_NAME/build/$BUILD_ID"

echo -e "${BLUE}⏳ Waiting for build to complete...${NC}"

# Wait for build to complete
while true; do
    BUILD_STATUS=$(aws codebuild batch-get-builds \
        --ids $BUILD_ID \
        --region $AWS_REGION \
        --query 'builds[0].buildStatus' \
        --output text)
    
    case $BUILD_STATUS in
        "SUCCEEDED")
            echo -e "${GREEN}🎉 Build completed successfully!${NC}"
            break
            ;;
        "FAILED"|"FAULT"|"STOPPED"|"TIMED_OUT")
            echo -e "${RED}❌ Build failed with status: $BUILD_STATUS${NC}"
            echo -e "${YELLOW}💡 Check logs at: https://eu-north-1.console.aws.amazon.com/codesuite/codebuild/projects/$PROJECT_NAME/build/$BUILD_ID${NC}"
            exit 1
            ;;
        "IN_PROGRESS")
            echo -e "${YELLOW}⏳ Build in progress...${NC}"
            sleep 30
            ;;
        *)
            echo -e "${YELLOW}⏳ Build status: $BUILD_STATUS${NC}"
            sleep 30
            ;;
    esac
done

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${BLUE}🔍 Verifying deployment...${NC}"

# Check ECR image
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
aws ecr describe-images \
    --repository-name $ECR_REPOSITORY \
    --region $AWS_REGION \
    --query 'imageDetails[0].{Digest:imageDigest,Tags:imageTags,Size:imageSizeInBytes,Date:imagePushedAt}' \
    --output table

echo -e "${GREEN}🎉 All done! Your Flutter ECS integration is now ACTIVE!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Test your Lambda endpoints"
echo "  2. Run 'flutter run' to see the integration in action"