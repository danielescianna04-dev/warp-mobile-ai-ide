# 🌐 Cloud Deployment Guide - Warp Mobile AI IDE

> **Da locale a globale - Deploy your AI IDE to the cloud!**

## 🎯 Architettura Cloud

```
┌─────────────────────────────────────┐
│        📱 Flutter Mobile Apps      │
│     (iOS, Android worldwide)        │
└─────────┬───────────────────────────┘
          │ HTTPS/WSS
┌─────────▼───────────────────────────┐
│      🌐 Google Cloud Run           │
│   (Auto-scaling, Global CDN)       │
├─────────────────────────────────────┤
│  🐳 Docker Container                │
│  • Node.js Backend                 │
│  • AI Agent                        │
│  • WebSocket Support               │
│  • Multi-user Sessions             │
└─────────┬───────────────────────────┘
          │ Secure API Calls
┌─────────▼───────────────────────────┐
│    🤖 AI Services (Multi-Cloud)    │
│  • OpenAI (GPT-5, GPT-4)           │
│  • Anthropic (Claude)              │  
│  • Google AI (Gemini)              │
└─────────────────────────────────────┘
```

## 🚀 Deploy Steps

### **Step 1: Setup Google Cloud** ☁️

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Login and create project
gcloud auth login
gcloud projects create warp-ai-ide-YOUR_SUFFIX
gcloud config set project warp-ai-ide-YOUR_SUFFIX

# Enable billing (required for Cloud Run)
# Vai su: https://console.cloud.google.com/billing
```

### **Step 2: Configure Secrets** 🔐

```bash
# Create secure secrets for API keys
gcloud secrets create ai-api-keys --data-file=- <<EOF
{
  "OPENAI_API_KEY": "sk-proj-your-real-openai-key",
  "GOOGLE_AI_API_KEY": "AIzaSy-your-real-google-key",
  "ANTHROPIC_API_KEY": "sk-ant-your-real-claude-key"
}
EOF
```

### **Step 3: Deploy Automatico** 🤖

```bash
# Deploy con un singolo comando!
./deploy-cloud.sh warp-ai-ide-YOUR_SUFFIX
```

### **Step 4: Update Flutter App** 📱

Aggiorna `lib/core/terminal/terminal_service.dart`:

```dart
import '../config/cloud_config.dart';

class TerminalService {
  // Usa CloudConfig invece di URL hardcoded
  late WebSocketChannel _channel;
  
  void connect() {
    final wsUrl = CloudConfig.webSocketUrl;
    print('🌐 Connecting to: $wsUrl');
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }
}
```

## 🌍 Vantaggi Cloud Deployment

### ✅ **Performance & Scalabilità:**
- **Auto-scaling**: Da 1 a 1000+ utenti automaticamente
- **Global CDN**: Latenza ridotta worldwide  
- **Load balancing**: Traffico distribuito intelligentemente
- **99.9% uptime**: SLA enterprise-grade

### ✅ **Sicurezza:**
- **HTTPS/WSS**: Tutto criptato end-to-end
- **Secret management**: API keys mai esposte 
- **Container isolation**: Ogni sessione utente isolata
- **IAM integration**: Controllo accessi granulare

### ✅ **Costi Ottimizzati:**
- **Pay-per-use**: Paghi solo per l'utilizzo reale
- **Cold start**: Container spenti quando non usati
- **Resource limits**: CPU/RAM ottimizzati

## 💰 Stima Costi (per 1000 utenti/mese)

### **Google Cloud Run:**
- **Compute**: ~$30-50/mese
- **Networking**: ~$10-20/mese  
- **Storage**: ~$5/mese
- **Total**: ~$45-75/mese

### **AI API Costs:**
- **OpenAI**: $50-200/mese (dipende dall'uso)
- **Google AI**: $20-100/mese (tier gratuita inclusa)
- **Anthropic**: $100-300/mese (qualità premium)

### **Total stimato**: $200-700/mese per 1000 utenti attivi

## 🌍 Regioni Disponibili

```bash
# Europa (raccomandato per utenti EU)
europe-west1  # Belgio
europe-west4  # Paesi Bassi

# USA (per utenti americani)
us-central1   # Iowa
us-east1      # South Carolina

# Asia (per utenti asiatici)
asia-east1    # Taiwan
asia-southeast1 # Singapore
```

## 📊 Monitoring & Analytics

### **Setup automatico incluso:**
- 📈 **Cloud Monitoring**: Performance, errori, latenza
- 📝 **Cloud Logging**: Log strutturati e ricercabili
- 🚨 **Alerting**: Notifiche automatic per problemi
- 📊 **Dashboards**: Metrics real-time

### **Metriche chiave monitorate:**
- WebSocket connections attive
- AI API latency & success rate  
- Memory/CPU usage
- Error rates & types
- User session durations

## 🔄 CI/CD Pipeline

Setup GitHub Actions per deploy automatici:

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
    - uses: actions/checkout@v3
    - uses: google-github-actions/setup-gcloud@v1
      with:
        project_id: ${{ secrets.GCP_PROJECT_ID }}
        service_account_key: ${{ secrets.GCP_SA_KEY }}
    - run: ./deploy-cloud.sh ${{ secrets.GCP_PROJECT_ID }}
```

## 🔧 Custom Domain Setup

```bash
# 1. Acquista dominio (es: warp-ai-ide.com)
# 2. Map domain to Cloud Run
gcloud run domain-mappings create \
    --service warp-mobile-ai-ide \
    --domain api.warp-ai-ide.com \
    --region europe-west1

# 3. Update DNS records come indicato
# 4. SSL certificates auto-provisioned!
```

## 📱 Flutter App Store Deploy

### **Per iOS:**
```bash
# Build production
flutter build ios --release \
    --dart-define=BACKEND_URL=https://api.warp-ai-ide.com

# Upload to App Store Connect
```

### **Per Android:**
```bash  
# Build production APK/AAB
flutter build appbundle --release \
    --dart-define=BACKEND_URL=https://api.warp-ai-ide.com

# Upload to Google Play Console
```

## 🌟 Advanced Features

### **Multi-Region Setup:**
Deploy in multiple regioni per performance globali ottimali:

```bash
# Deploy in Europa
./deploy-cloud.sh warp-ai-ide-eu europe-west1

# Deploy in USA  
./deploy-cloud.sh warp-ai-ide-us us-central1

# Deploy in Asia
./deploy-cloud.sh warp-ai-ide-asia asia-east1
```

### **A/B Testing:**
Test diverse versioni dell'AI Agent:

```bash
# Deploy versione "experimental"
gcloud run deploy warp-mobile-ai-ide-experimental \
    --image gcr.io/your-project/warp-mobile-ai-ide:experimental \
    --tag experimental

# Traffic split 90/10
gcloud run services update-traffic warp-mobile-ai-ide \
    --to-revisions=LATEST=90,experimental=10
```

## 🎯 Go Live Checklist

- [ ] ✅ Deploy backend su Cloud Run
- [ ] 🔐 API keys configurate nei secrets
- [ ] 📊 Monitoring abilitato
- [ ] 🧪 Load testing completato  
- [ ] 📱 Flutter app configurata per produzione
- [ ] 🌐 Custom domain configurato (opzionale)
- [ ] 📱 App store listing preparato
- [ ] 💰 Billing alerts configurati
- [ ] 👥 Team access configurato
- [ ] 📚 Documentation aggiornata

## 🚨 Emergency Procedures

### **Rollback rapido:**
```bash
# Torna alla versione precedente
gcloud run services update-traffic warp-mobile-ai-ide \
    --to-revisions=PREVIOUS=100
```

### **Scale a zero (emergenza costi):**
```bash
# Ferma tutto il traffico
gcloud run services update warp-mobile-ai-ide \
    --max-instances=0
```

### **Debug production:**
```bash
# Live logs
gcloud run services logs read warp-mobile-ai-ide \
    --follow --region europe-west1
```

---

## 🎉 Congratulazioni!

Una volta completato il deploy, la tua **Warp Mobile AI IDE** sarà:

- 🌍 **Disponibile globalmente** 24/7
- ⚡ **Auto-scaling** basato sulla domanda  
- 🔐 **Sicura** con HTTPS e secrets management
- 📊 **Monitorata** con dashboards automatici
- 💰 **Cost-effective** con pay-per-use
- 🚀 **Pronta** per migliaia di utenti

**Welcome to the global AI IDE revolution! 🤖✨**