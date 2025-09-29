# 🚀 Istruzioni per Deploy Docker su AWS ECS (CloudShell)

## 📦 Pacchetto Ottimizzato
Ho creato un pacchetto molto più leggero (**34KB** vs 257MB precedente) che esclude `node_modules` e altri file non necessari. Le dipendenze npm verranno installate direttamente dentro il container Docker durante il build.

## 🔧 File Inclusi nel Pacchetto
- `build-and-deploy.sh` - Script principale ottimizzato
- `backend/package.json` - Dipendenze npm
- `backend/package-lock.json` - Versioni precise delle dipendenze  
- `backend/Dockerfile.ecs` - Dockerfile per ECS
- `backend/ecs-server.js` - Server backend Flutter
- `.dockerignore` - Regole di esclusione Docker

## 📋 Procedura CloudShell

### 1. Apri AWS CloudShell
- Vai su [AWS Console](https://console.aws.amazon.com)
- Cambia regione in **eu-north-1** (Stockholm)
- Clicca sull'icona CloudShell nella barra superiore

### 2. Carica il Pacchetto
```bash
# Carica docker-build-package.tar.gz usando il menu Actions > Upload
```

### 3. Estrai e Esegui
```bash
# Estrai il pacchetto
tar -xzf docker-build-package.tar.gz

# Verifica i file estratti
ls -la

# Rendi eseguibile lo script
chmod +x build-and-deploy.sh

# Esegui il deployment
./build-and-deploy.sh
```

## 🎯 Cosa Fa lo Script

### ✅ Verifica Prerequisiti
- Controlla che esistano tutti i file necessari
- Verifica configurazione AWS
- Mostra informazioni sull'account e regione

### 🔨 Build Docker
- Costruisce l'immagine Docker usando `Dockerfile.ecs`
- Installa automaticamente le dipendenze npm dentro il container
- Ottimizza l'immagine per produzione

### 📤 Deploy ECR
- Fa login automatico in AWS ECR
- Tagga l'immagine con `:latest`
- Carica l'immagine nel repository ECR
- Verifica che l'upload sia andato a buon fine

### 🔄 Aggiorna ECS
- Triggera automaticamente un nuovo deployment del servizio ECS
- Forza il download della nuova immagine
- Il servizio ECS si aggiornerà automaticamente

## 📊 Output Atteso
```
🚀 Starting Docker build and ECR deployment...
📋 Configuration:
  AWS Region: eu-north-1
  ECR Repository: flutter-ecs-app
  ECR URI: 123456789012.dkr.ecr.eu-north-1.amazonaws.com/flutter-ecs-app
  AWS Account: 123456789012

✅ All required files found
🔧 Building Docker image (npm install inside container)...
✅ Docker image built successfully
🔐 Logging into AWS ECR...
✅ ECR login successful
🏷️ Tagging image...
📤 Pushing to ECR...
✅ Image pushed to ECR successfully!
🔄 Updating ECS service...
✅ ECS service deployment triggered
```

## 🎉 Risultato Finale
Dopo l'esecuzione completa:

1. ✅ **Immagine Docker** caricata in ECR
2. ✅ **Servizio ECS** aggiornato automaticamente
3. ✅ **Lambda API** ora trova l'immagine e può avviare i container
4. ✅ **Integrazione ECS** completamente attiva

## 🔍 Verifica Stato
Dopo il deployment, puoi testare:

```bash
# Testa l'endpoint health
curl https://your-api-id.execute-api.eu-north-1.amazonaws.com/prod/health

# Dovrebbe restituire:
# {"status": "healthy", "integration": "ACTIVE ✅ Real ECS integration enabled"}
```

## 💡 Vantaggi di questo Approccio
- **Pacchetto ultra-leggero**: 34KB invece di 257MB
- **Build automatizzato**: npm install dentro Docker
- **Zero configurazione manuale**: tutto automatico
- **Rollback facile**: versioni separate in ECR
- **Monitoraggio integrato**: output dettagliato

## 🚨 Se Qualcosa Va Storto
Lo script si fermerà automaticamente in caso di errori. Controlla:

1. **Connessione AWS**: Assicurati di essere nella regione `eu-north-1`
2. **Permessi**: CloudShell dovrebbe avere tutti i permessi necessari
3. **Repository ECR**: Deve esistere `flutter-ecs-app` nella regione
4. **Servizio ECS**: Deve esistere il cluster e servizio configurati

Il pacchetto è ora pronto per il caricamento in CloudShell! 🎯