# 🚀 Warp Mobile AI IDE - Production Deployment Guide

## Overview

This guide helps you deploy Warp Mobile AI IDE to production using Google Cloud Run with **multi-tenant architecture** and **user isolation**. Users don't need Docker installed locally - everything runs securely in the cloud.

## 🏗️ Architecture

### Production Features
- ✅ **Multi-tenant**: Supports multiple users simultaneously
- ✅ **User Isolation**: Each user gets their own secure workspace
- ✅ **No Docker Required**: Users connect directly via web/mobile app
- ✅ **Auto-scaling**: Scales based on demand
- ✅ **Security**: Command filtering, resource limits, sandboxed execution
- ✅ **Quotas**: 100MB storage per user, 30s command timeout
- ✅ **Persistent Workspaces**: User files persist between sessions

### Technology Stack
- **Backend**: Node.js with WebSocket support
- **Container**: Docker with security hardening
- **Cloud**: Google Cloud Run (serverless containers)
- **AI**: OpenAI, Google AI, Anthropic integration
- **Security**: Helmet.js, command filtering, isolated workspaces

## 📋 Prerequisites

### Required Tools
```bash
# Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Docker Desktop
# Download from: https://docs.docker.com/get-docker/
```

### Google Cloud Setup
1. Create a Google Cloud Project
2. Enable billing for the project
3. Install and authenticate gcloud CLI:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

## 🔧 Deployment Steps

### 1. Prepare Environment
```bash
# Clone the repository (if not already done)
git clone <your-repo-url>
cd warp-mobile-ai-ide

# Ensure .env file exists with your API keys
cp .env.example .env
# Edit .env with your actual API keys:
# OPENAI_API_KEY=your-key-here
# GOOGLE_AI_API_KEY=your-key-here  
# ANTHROPIC_API_KEY=your-key-here
```

### 2. Deploy to Google Cloud Run
```bash
# Run the deployment script
./deploy-cloud.sh YOUR_PROJECT_ID [REGION]

# Example:
./deploy-cloud.sh my-warp-project us-central1
```

### 3. Update Frontend Configuration
After deployment, update your Flutter/React app configuration:

```dart
// Flutter example
class AppConfig {
  static const String apiBaseUrl = 'https://your-service-url.run.app';
  static const String wsBaseUrl = 'wss://your-service-url.run.app';
}
```

## 🔒 Security Features

### User Isolation
- Each user gets isolated workspace: `/tmp/warp-users/{userHash}/`
- Commands can't escape user directory
- Process isolation with timeouts
- Resource quotas per user

### Command Security
Blocked commands include:
- System destruction: `rm -rf /`, `shutdown`, `reboot`
- Privilege escalation: `sudo`, `su`
- Directory traversal: `../../../`
- System file access: `/etc/passwd`, `/etc/shadow`

### Environment Security
- Non-root container execution
- Helmet.js security headers
- Environment variable isolation
- Process timeout limits (30s)

## 📊 Monitoring & Management

### View Logs
```bash
# Real-time logs
gcloud logs tail --service=warp-mobile-ai-ide --region=us-central1

# Recent logs
gcloud logs read --service=warp-mobile-ai-ide --region=us-central1 --limit=100
```

### Service Management
```bash
# View service details
gcloud run services describe warp-mobile-ai-ide --region=us-central1

# Scale the service
gcloud run services update warp-mobile-ai-ide \
  --region=us-central1 \
  --max-instances=20

# Update with new image
gcloud run services update warp-mobile-ai-ide \
  --region=us-central1 \
  --image=gcr.io/YOUR_PROJECT/warp-mobile-ai-ide
```

### Cost Optimization
```bash
# Set minimum instances to 0 for cost savings
gcloud run services update warp-mobile-ai-ide \
  --region=us-central1 \
  --min-instances=0 \
  --max-instances=10
```

## 🎯 Production vs Local Mode

| Feature | Local Mode | Production Mode |
|---------|------------|-----------------|
| Users | Single user | Multi-tenant |
| Isolation | None | Per-user workspaces |
| Security | Basic | Hardened with filtering |
| Scaling | Manual | Auto-scaling |
| Docker | Required locally | Cloud-managed |
| Quotas | Unlimited | 100MB per user |
| Timeouts | Unlimited | 30s per command |
| Persistence | Host filesystem | Container storage |

## 🚨 Troubleshooting

### Common Issues

**1. Deployment fails with "Permission denied"**
```bash
# Ensure you're authenticated
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

**2. Service URL not accessible**
```bash
# Check service status
gcloud run services list --region=us-central1

# Check logs for errors
gcloud logs tail --service=warp-mobile-ai-ide --region=us-central1
```

**3. AI commands not working**
- Verify API keys are set in .env file
- Check Cloud Run environment variables
- Review service logs for API errors

**4. WebSocket connection fails**
- Ensure frontend uses `wss://` protocol
- Check CORS configuration in server
- Verify WebSocket URL format

### Health Checks
```bash
# Check service health
curl https://your-service-url.run.app/health

# Expected response:
# {"status":"ok","timestamp":"2024-01-01T00:00:00.000Z","version":"1.0.0"}
```

## 🔄 CI/CD Pipeline (Optional)

For automatic deployments on code changes:

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloud Run
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - id: auth
      uses: google-github-actions/auth@v0
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}
    - name: Deploy
      run: ./deploy-cloud.sh ${{ secrets.GCP_PROJECT_ID }}
```

## 💰 Cost Estimation

Google Cloud Run pricing (approximate):
- **Free tier**: 2 million requests/month
- **CPU**: $0.00002400 per vCPU-second
- **Memory**: $0.00000250 per GB-second
- **Requests**: $0.40 per million requests

**Example monthly cost for moderate usage:**
- 10,000 sessions/month
- 30 seconds average session
- ~$5-15/month

## 📞 Support

For issues:
1. Check logs: `gcloud logs tail --service=warp-mobile-ai-ide`
2. Review this documentation
3. Check Google Cloud Console
4. Open GitHub issue with logs and configuration

## 🎉 Success!

Your Warp Mobile AI IDE is now running in production with:
- 🌐 Global accessibility
- 🔒 Multi-tenant security
- 🚀 Auto-scaling capabilities
- 💾 Persistent user workspaces
- 🤖 Full AI agent integration

Users can now connect from anywhere without needing Docker installed locally!