# 🚀 Deploy Immediato - Fix Container ECS

## ❌ Problema Attuale
Il container ECS **non ha Flutter installato** → comandi Flutter falliscono

## ✅ Soluzione

### 1. Deploy Nuovo Container (con Flutter)

```bash
cd /Users/getmad/Projects/warp-mobile-ai-ide/backend
bash deploy-ecs-flutter.sh
```

**Tempo stimato**: 10-15 minuti (build + deploy)

### 2. Monitora Deploy

```bash
# Verifica service update
aws ecs describe-services \
  --cluster warp-flutter-cluster \
  --services warp-flutter-service \
  --region us-west-2 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Events:events[0:3]}'

# Segui i log
aws logs tail /ecs/warp-flutter-service --follow --region us-west-2
```

### 3. Test Dopo Deploy

```bash
# Test Flutter
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"flutter --version","repository":"test"}'

# Test Flutter doctor
curl http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/flutter/doctor
```

---

## 🔄 Alternativa: Usa Container Esistente (se hai già buildato)

Se hai già un'immagine con Flutter in ECR:

```bash
# Lista immagini disponibili
aws ecr describe-images \
  --repository-name warp-ecs-flutter \
  --region us-west-2 \
  --query 'imageDetails[*].{Tags:imageTags,Pushed:imagePushedAt}' \
  --output table

# Update service con immagine specifica
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --force-new-deployment \
  --region us-west-2
```

---

## 📊 Verifica Stato Attuale

```bash
# Container attuale (SENZA Flutter)
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"which flutter","repository":"test"}'

# Output atteso PRIMA del fix:
# {"success":true,"output":"","error":"bash: line 1: flutter: command not found\n",...}

# Output atteso DOPO il fix:
# {"success":true,"output":"/opt/flutter/bin/flutter\n","error":"",...}
```

---

## ⚡ Quick Fix (se non vuoi rebuilddare)

Usa comandi che non richiedono Flutter:

```bash
# Test con comandi base
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"echo Hello from ECS","repository":"test"}'

curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"node --version","repository":"test"}'
```

---

## 🎯 Prossimi Passi

1. ✅ **Esegui deploy**: `bash deploy-ecs-flutter.sh`
2. ⏳ **Attendi 10-15 min** (build + deploy)
3. ✅ **Testa Flutter**: `curl ... /execute-heavy`
4. ✅ **Testa app Flutter mobile** con comando `flutter run`

---

## 🆘 Troubleshooting

### Build fallisce?
```bash
# Verifica Docker
docker --version

# Verifica AWS CLI
aws --version

# Verifica credenziali
aws sts get-caller-identity
```

### Deploy lento?
```bash
# Forza stop vecchio task
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --desired-count 0 \
  --region us-west-2

# Poi riporta a 1
aws ecs update-service \
  --cluster warp-flutter-cluster \
  --service warp-flutter-service \
  --desired-count 1 \
  --region us-west-2
```
