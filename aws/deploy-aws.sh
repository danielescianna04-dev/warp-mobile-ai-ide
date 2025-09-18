#!/bin/bash

# 🚀 Warp Mobile AI IDE - AWS Deployment Script
# Automated deployment to AWS Lambda + EFS

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Warp Mobile AI IDE - AWS Deployment${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Configuration
PROJECT_NAME="warp-mobile-ai-ide"
ENVIRONMENT="prod"
REGION="us-east-1"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
LAMBDA_ZIP="lambda-deployment.zip"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${BLUE}🔍 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  AWS credentials not configured. Please run:${NC}"
    echo -e "${YELLOW}   aws configure${NC}"
    echo -e "${YELLOW}   Enter your AWS Access Key ID and Secret${NC}\n"
    
    echo -e "${BLUE}💡 Need AWS credentials? Here's how to get them:${NC}"
    echo -e "1. Go to AWS Console -> IAM -> Users -> Your User"
    echo -e "2. Security credentials -> Create access key"
    echo -e "3. Download the key and use it in 'aws configure'\n"
    
    read -p "Press ENTER when you have configured AWS credentials..." -n 1 -r
    echo
    
    # Test again
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo -e "${RED}❌ AWS credentials still not working. Please check your setup.${NC}"
        exit 1
    fi
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS credentials configured for account: ${AWS_ACCOUNT_ID}${NC}\n"

# Step 1: Deploy CloudFormation Infrastructure
echo -e "${BLUE}📋 Step 1: Deploying CloudFormation infrastructure...${NC}"
cd "$(dirname "$0")"

aws cloudformation deploy \
    --template-file cloudformation-template.yaml \
    --stack-name ${STACK_NAME} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        Environment=${ENVIRONMENT} \
    --region ${REGION}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ CloudFormation deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}\n"

# Get stack outputs
echo -e "${BLUE}📊 Getting stack outputs...${NC}"
API_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text \
    --region ${REGION})

LAMBDA_FUNCTION=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionName`].OutputValue' \
    --output text \
    --region ${REGION})

EFS_ID=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`EFSFileSystemId`].OutputValue' \
    --output text \
    --region ${REGION})

echo -e "${GREEN}API Gateway URL: ${API_URL}${NC}"
echo -e "${GREEN}Lambda Function: ${LAMBDA_FUNCTION}${NC}"
echo -e "${GREEN}EFS File System: ${EFS_ID}${NC}\n"

# Step 2: Package Lambda Function
echo -e "${BLUE}📦 Step 2: Packaging Lambda function...${NC}"
cd ../backend

# Create temp directory for packaging
mkdir -p lambda-package
cp -r lambda/* lambda-package/
cp ai-agent.js lambda-package/

# Copy package.json and install production dependencies
cat > lambda-package/package.json << 'EOF'
{
  "name": "warp-mobile-ai-ide-lambda",
  "version": "1.0.0",
  "description": "Warp Mobile AI IDE Lambda Functions",
  "main": "command-handler.js",
  "dependencies": {
    "uuid": "^9.0.0",
    "aws-sdk": "^2.1490.0"
  }
}
EOF

cd lambda-package
npm install --production
cd ..

# Create deployment zip
echo -e "${BLUE}🗜️  Creating deployment package...${NC}"
cd lambda-package
zip -r ../${LAMBDA_ZIP} . > /dev/null
cd ..

echo -e "${GREEN}✅ Lambda package created: ${LAMBDA_ZIP} ($(du -h ${LAMBDA_ZIP} | cut -f1))${NC}\n"

# Step 3: Update Lambda Function
echo -e "${BLUE}☁️  Step 3: Deploying Lambda function...${NC}"
aws lambda update-function-code \
    --function-name ${LAMBDA_FUNCTION} \
    --zip-file fileb://${LAMBDA_ZIP} \
    --region ${REGION}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Lambda deployment failed${NC}"
    exit 1
fi

# Wait for function update to complete
echo -e "${YELLOW}⏳ Waiting for function update to complete...${NC}"
aws lambda wait function-updated \
    --function-name ${LAMBDA_FUNCTION} \
    --region ${REGION}

echo -e "${GREEN}✅ Lambda function deployed successfully!${NC}\n"

# Step 4: Test Deployment
echo -e "${BLUE}🧪 Step 4: Testing deployment...${NC}"

# Test health endpoint
echo -e "${YELLOW}Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -X GET "${API_URL}/health" || echo "ERROR")

if [[ $HEALTH_RESPONSE == *"ok"* ]]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed: ${HEALTH_RESPONSE}${NC}"
fi

# Test session creation
echo -e "${YELLOW}Testing session creation...${NC}"
SESSION_RESPONSE=$(curl -s -X POST "${API_URL}/session/create" \
    -H "X-User-ID: testuser" \
    -H "Content-Type: application/json" || echo "ERROR")

if [[ $SESSION_RESPONSE == *"success"* ]]; then
    echo -e "${GREEN}✅ Session creation test passed${NC}"
else
    echo -e "${RED}❌ Session creation test failed: ${SESSION_RESPONSE}${NC}"
fi

# Clean up
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -f ${LAMBDA_ZIP}
rm -rf lambda-package

echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🌐 API Gateway URL: ${API_URL}${NC}"
echo -e "${GREEN}🧪 Health Check: ${API_URL}/health${NC}"
echo -e "${GREEN}📊 AWS Console: https://console.aws.amazon.com/lambda/home?region=${REGION}#/functions/${LAMBDA_FUNCTION}${NC}\n"

echo -e "${YELLOW}💡 Next Steps:${NC}"
echo -e "1. Update your Flutter app with the new API URL:"
echo -e "   ${API_URL}"
echo -e "2. Test the app end-to-end"
echo -e "3. Monitor CloudWatch logs for any issues\n"

echo -e "${GREEN}✅ Your Warp Mobile AI IDE is now running serverless on AWS! 🚀${NC}"