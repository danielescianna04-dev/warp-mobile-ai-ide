# 🚀 Build Container con Flutter via CloudShell

## 📋 Procedura Completa (10 minuti)

### 1. Apri AWS CloudShell
```
https://us-west-2.console.aws.amazon.com/cloudshell
```

### 2. Carica i file necessari

Clicca su **Actions → Upload files** e carica:
- `Dockerfile.ecs`
- `ecs-server.js`
- `package.json`

### 3. Esegui questi comandi in CloudShell

```bash
# Variabili
REGION="us-west-2"
ACCOUNT_ID="703686967361"
REPO_NAME="warp-ecs-flutter"
IMAGE_TAG="with-flutter"

# Login ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build (10-15 min)
docker build -f Dockerfile.ecs -t $REPO_NAME:$IMAGE_TAG .

# Tag
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# Push
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "✅ Immagine pushata: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"
```

### 4. Update Task Definition (dal tuo Mac)

```bash
# Crea task definition con nuova immagine
cat > /tmp/task-def-new.json << 'EOF'
{
  "family": "warp-flutter-web-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [{
    "name": "warp-flutter-container",
    "image": "703686967361.dkr.ecr.us-west-2.amazonaws.com/warp-ecs-flutter:with-flutter",
    "essential": true,
    "portMappings": [{"containerPort": 3000, "protocol": "tcp"}],
    "environment": [
      {"name": "PORT", "value": "3000"},
      {"name": "FLUTTER_HOME", "value": "/opt/flutter"},
      {"name": "PATH", "value": "/opt/flutter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/warp-flutter-service",
        "awslogs-region": "us-west-2",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }],
  "executionRoleArn": "arn:aws:iam::703686967361:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::703686967361:role/ecsTaskExecutionRole"
}
EOF

# Registra
aws ecs register-task-definition --cli-input-json file:///tmp/task-def-new.json --region us-west-2

# Update service
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --task-definition warp-flutter-web-task \
  --force-new-deployment \
  --region us-west-2
```

### 5. Test

```bash
# Attendi 2-3 minuti poi testa
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"flutter --version","repository":"test"}'
```

## ⏱️ Timeline

- Upload files: 1 min
- Docker build: 10-15 min
- Push ECR: 2-3 min
- Deploy ECS: 2-3 min
- **TOTALE: ~20 minuti**

## 🆘 Alternative Veloci

Se non vuoi aspettare, puoi:
1. Testare con comandi non-Flutter (node, python, echo)
2. Usare mock mode nell'app Flutter
3. Aspettare che qualcuno con Docker locale faccia il build
