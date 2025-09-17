# 🚀 Warp Mobile AI IDE - Guida Setup e Utilizzo

## 📋 Panoramica Sistema

Warp Mobile AI IDE è un sistema innovativo che combina:
- **Backend Node.js**: Server che gestisce containers Docker per l'esecuzione di codice
- **Flutter App**: Frontend mobile che si connette al backend via WebSocket
- **Docker Containers**: Ambienti di sviluppo isolati con tutti gli strumenti necessari

## 🏗️ Architettura Sistema

```
┌─────────────────┐    WebSocket     ┌─────────────────┐    Docker API    ┌─────────────────┐
│                 │ ◄──────────────► │                 │ ◄──────────────► │                 │
│   Flutter App   │                  │  Node.js        │                  │   Docker        │
│   (iPhone/      │                  │  Backend        │                  │   Containers    │
│   Android)      │                  │                 │                  │                 │
└─────────────────┘                  └─────────────────┘                  └─────────────────┘
```

## ⚙️ Setup Completo

### 1. Prerequisiti

**Sistema Mac:**
- Docker Desktop installato e in esecuzione
- Node.js 18+ installato
- Flutter SDK installato (per app mobile)
- Xcode (per iOS) o Android Studio (per Android)

**Verifica prerequisiti:**
```bash
# Verifica Docker
docker --version
docker ps

# Verifica Node.js
node --version
npm --version

# Verifica Flutter (opzionale)
flutter doctor
```

### 2. Setup Backend

**Clona il repository:**
```bash
git clone https://github.com/tuo-username/warp-mobile-ai-ide.git
cd warp-mobile-ai-ide
```

**Setup del backend:**
```bash
cd backend

# Installa dipendenze
npm install

# Verifica file di configurazione
ls -la

# Avvia il server
npm start
# oppure
node server.js
```

**Il server sarà disponibile su:**
- HTTP: `http://localhost:3001`
- WebSocket: `ws://localhost:3001`
- Health Check: `http://localhost:3001/health`

### 3. Costruzione Docker Image

**Naviga nella directory backend:**
```bash
cd backend
```

**Costruisci l'immagine Docker:**
```bash
# Costruzione immagine di sviluppo
docker build -t warp-dev-simple:latest -f Dockerfile.simple .

# Verifica che l'immagine sia stata creata
docker images | grep warp-dev
```

### 4. Setup Flutter App

**Naviga nella directory principale:**
```bash
cd ..  # Torna alla root del progetto
```

**Configura dipendenze Flutter:**
```bash
flutter pub get
```

**Configura l'IP del backend nell'app:**

1. Trova l'IP LAN del tuo Mac:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

2. Modifica il file Flutter per utilizzare l'IP corretto (sostituisci `192.168.1.49` con il tuo IP):
```dart
// In lib/main.dart o nel file di configurazione WebSocket
final websocketUrl = 'ws://192.168.1.49:3001';
```

**Avvia l'app Flutter:**
```bash
# Per iOS Simulator
flutter run -d ios

# Per Android Emulator
flutter run -d android

# Per dispositivo fisico
flutter run
```

## 🎯 Utilizzo del Sistema

### Flusso di Lavoro Base

1. **Avvia Backend**: Assicurati che il server Node.js sia in esecuzione
2. **Apri Flutter App**: Lancia l'app su iPhone/Android
3. **Connessione**: L'app si connette automaticamente al backend
4. **Inizializzazione**: Il sistema crea un container Docker dedicato
5. **Sviluppo**: Usa il terminale mobile per sviluppare

### Comandi Supportati

**Comandi di base:**
```bash
# Navigazione
pwd
ls -la
cd directory

# Gestione file
mkdir nuovo-progetto
touch file.txt
nano file.txt
cat file.txt

# Git
git clone https://github.com/user/repo.git
git status
git add .
git commit -m "messaggio"
```

**Creazione progetti:**
```bash
# React con Vite
npm create vite@latest my-app -- --template react
cd my-app
npm install
npm run dev

# React classico
npx create-react-app my-app
cd my-app
npm start

# Python server
python3 -m http.server 8000

# Flask app
pip install flask
python app.py
```

**Strumenti di sviluppo disponibili nel container:**
- Node.js 20.x + npm
- Python 3.9 + pip
- Git
- Curl, wget
- Vim, nano
- Alpine Linux package manager (apk)

### Gestione Server Web

Il sistema rileva automaticamente server web avviati nel container:

**Porte monitorate:**
- 3000: React, Node.js
- 3001: React alternative
- 4200: Angular
- 5000: Flask
- 8000: Django/Python
- 8080: Java/Tomcat
- 8888: Jupyter
- 9000: Go/PHP

**Quando avvii un server**, il sistema:
1. Rileva automaticamente il server
2. Mappa la porta container → porta host
3. Invia notifica all'app Flutter
4. Fornisce URL di preview: `/preview/{sessionId}/`

### API Endpoints

**Health Check:**
```bash
curl http://localhost:3001/health
```

**Container Status:**
```bash
curl http://localhost:3001/containers
```

**Preview Info:**
```bash
curl http://localhost:3001/api/preview
curl http://localhost:3001/api/preview/{sessionId}
```

## 🔧 Troubleshooting

### Problemi Comuni

**1. Backend non si connette:**
```bash
# Verifica che la porta 3001 sia libera
lsof -i :3001

# Riavvia il backend
pkill -f "node server.js"
cd backend && node server.js
```

**2. Flutter App non si connette:**
- Verifica l'IP nel codice Flutter
- Assicurati che backend e app siano sulla stessa rete
- Controlla firewall/antivirus

**3. Docker Container non si crea:**
```bash
# Verifica Docker
docker ps -a

# Rimuovi container vecchi
docker container prune

# Ricostruisci immagine
cd backend
docker build -t warp-dev-simple:latest -f Dockerfile.simple .
```

**4. Comandi falliscono nel container:**
- Il sistema usa TTY fallback automatico
- Alcuni comandi interattivi potrebbero non funzionare
- Usa `exit` per terminare processi bloccati

### Log di Debug

**Backend logs:**
```bash
# I log sono mostrati nella console dove hai avviato il server
# Cerca messaggi con timestamp: [2024-XX-XX...]
```

**Flutter logs:**
```bash
# Durante flutter run, i log appaiono nella console
flutter logs
```

**Container logs:**
```bash
# Trova il container ID
docker ps

# Vedi i log del container
docker logs <container-id>
```

## 🚀 Funzionalità Avanzate

### Session Management
- Ogni user ha una sessione persistente
- I container vengono riutilizzati tra connessioni
- Cleanup automatico dopo 30 minuti di inattività

### Web Server Detection
- Rilevamento automatico di 20+ framework
- Mapping automatico porte container → host
- Notifiche real-time all'app Flutter

### Error Handling Robusto
- TTY fallback per comandi complessi
- Timeout automatico (5 minuti)
- Limitazione output (1MB max)
- Gestione disconnessioni graceful

### Performance Optimizations
- Riuso sessioni esistenti
- Limitazione memoria container (2GB)
- Cleanup automatico risorse
- Logging strutturato con timestamp

## 📊 Monitoring

### Metriche Disponibili

**Via /health endpoint:**
- Status server
- Sessioni attive
- Timestamp ultimo health check

**Via /api/preview endpoint:**
- Server web attivi
- Statistiche preview
- Info per ogni sessione

**Logs strutturati:**
- Connessioni WebSocket
- Esecuzione comandi
- Eventi container
- Errori e warning

## 🎨 Personalizzazione

### Backend Configuration
```javascript
// In server.js, puoi modificare:
const PORT = process.env.PORT || 3001;
const CONTAINER_MEMORY = 2 * 1024 * 1024 * 1024; // 2GB
const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minuti
const COMMAND_TIMEOUT = 5 * 60 * 1000; // 5 minuti
```

### Container Customization
```bash
# Modifica Dockerfile.simple per aggiungere strumenti
RUN apk add --no-cache additional-package

# Ricostruisci immagine dopo modifiche
docker build -t warp-dev-simple:latest -f Dockerfile.simple .
```

### Flutter App Customization
```dart
// Modifica WebSocket URL, timeout, UI theme
// in lib/main.dart o nei file di configurazione
```

## 📈 Estensioni Future

Il sistema è progettato per supportare:
- AI Integration (ChatGPT, Claude, Gemini)
- Multiple container environments
- Real-time collaboration
- Cloud deployment
- Advanced project templates
- Integrated debugging tools

---

## 🤝 Contribuire

1. Fork il repository
2. Crea un branch per la tua feature: `git checkout -b feature/nome-feature`
3. Commit le modifiche: `git commit -m 'Aggiungi nome-feature'`
4. Push al branch: `git push origin feature/nome-feature`
5. Apri una Pull Request

## 📄 Licenza

MIT License - vedi [LICENSE](LICENSE) per dettagli.

---

**Happy Coding! 🎉**

Per supporto o domande, apri un issue su GitHub o contatta il team di sviluppo.