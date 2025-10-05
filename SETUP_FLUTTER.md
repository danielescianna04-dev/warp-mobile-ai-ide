# 🚀 Setup Flutter su ECS - Guida Completa

## 📊 Situazione Attuale

```
✅ ECS Container: FUNZIONANTE (Node.js, comandi base)
❌ Flutter: NON INSTALLATO
🎯 Obiettivo: Aggiungere Flutter al container
```

## 🔧 Procedura (20 minuti totali)

### STEP 1: Prepara i file (1 min)

Apri 3 file in un editor:
- `backend/Dockerfile.ecs`
- `backend/ecs-server.js`
- `backend/package.json`

### STEP 2: Apri AWS CloudShell (1 min)

1. Vai su: https://us-west-2.console.aws.amazon.com/cloudshell
2. Attendi che CloudShell si avvii (30 sec)

### STEP 3: Carica i file (2 min)

1. Clicca su **Actions** (in alto a destra)
2. Seleziona **Upload files**
3. Carica questi 3 file:
   - `Dockerfile.ecs`
   - `ecs-server.js`
   - `package.json`

### STEP 4: Esegui build in CloudShell (15 min)

Copia e incolla questo blocco completo:

```bash
# Variabili
REGION="us-west-2"
ACCOUNT_ID="703686967361"
REPO_NAME="warp-ecs-flutter"
IMAGE_TAG="with-flutter"

# Login ECR
echo "1️⃣ Login to ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build (10-15 min)
echo "2️⃣ Building Docker image..."
docker build -f Dockerfile.ecs -t $REPO_NAME:$IMAGE_TAG .

# Tag
echo "3️⃣ Tagging..."
docker tag $REPO_NAME:$IMAGE_TAG \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# Push
echo "4️⃣ Pushing to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "✅ Build completato!"
```

**⏳ Attendi 10-15 minuti** mentre Docker builda l'immagine.

### STEP 5: Update ECS Service (2 min)

**Sul tuo Mac**, esegui:

```bash
cd /Users/getmad/Projects/warp-mobile-ai-ide/backend
bash update-ecs-service.sh
```

### STEP 6: Test (1 min)

Attendi 2-3 minuti poi testa:

```bash
# Test Flutter
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"flutter --version","repository":"test"}'

# Output atteso:
# {"success":true,"output":"Flutter 3.x.x...","error":"","exitCode":0,...}
```

---

## 🎯 Dopo il Setup

### Test Flutter Run

```bash
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/flutter/run \
  -H "Content-Type: application/json" \
  -d '{"repository":"my-app","command":"flutter run"}'
```

### Test dall'App Flutter

1. Apri l'app Flutter mobile
2. Esegui comando: `flutter run`
3. Dovresti vedere il **Preview Button** con URL! 🎉

---

## 🆘 Troubleshooting

### Build fallisce in CloudShell?

```bash
# Verifica spazio disco
df -h

# Se pieno, pulisci
docker system prune -a -f
```

### Service non si aggiorna?

```bash
# Forza stop vecchio task
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --desired-count 0 \
  --region us-west-2

# Attendi 30 sec, poi riavvia
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --desired-count 1 \
  --region us-west-2
```

### Flutter non funziona dopo deploy?

```bash
# Verifica log container
aws logs tail /ecs/warp-flutter-service --follow --region us-west-2

# Verifica task definition
aws ecs describe-task-definition \
  --task-definition warp-flutter-web-task \
  --region us-west-2 \
  --query 'taskDefinition.containerDefinitions[0].environment'
```

---

## 📝 File Creati

- ✅ `cloudshell-commands.txt` - Comandi per CloudShell
- ✅ `update-ecs-service.sh` - Script update service
- ✅ `SETUP_FLUTTER.md` - Questa guida

---

## ⏱️ Timeline Completa

| Step | Tempo | Azione |
|------|-------|--------|
| 1 | 1 min | Prepara file |
| 2 | 1 min | Apri CloudShell |
| 3 | 2 min | Upload file |
| 4 | 15 min | Docker build |
| 5 | 2 min | Update service |
| 6 | 1 min | Test |
| **TOTALE** | **~22 min** | |

---

## 🎉 Risultato Finale

Dopo il setup avrai:
- ✅ Container ECS con Flutter installato
- ✅ Comandi Flutter funzionanti
- ✅ Preview button nell'app mobile
- ✅ Hot reload per Flutter web apps

**Pronto per iniziare?** Apri CloudShell! 🚀
