# 🏠 Local Mode - Warp Mobile AI IDE

> **Modalità locale senza Docker - Sviluppa direttamente sul tuo sistema!**

## 🎯 Cos'è la Local Mode?

La Local Mode ti permette di usare Warp Mobile AI IDE **senza Docker**, eseguendo i comandi direttamente sul tuo sistema macOS/Linux. È perfetto per:

- 🚀 **Setup più veloce** - Non serve Docker
- 💻 **Accesso completo** - Usa tutti i tool del tuo sistema
- 🔧 **Development rapido** - Niente overhead di container
- 🏠 **Workspace locale** - I file restano sul tuo Mac

## 🚀 Quick Start

### 1. Avvia il backend in modalità locale
```bash
cd backend
npm run local
```

Vedrai:
```
🚀 Warp Mobile AI IDE - Local Mode Server
📡 WebSocket server running on ws://localhost:3001
💻 Running in LOCAL mode (no Docker required)
🏠 Workspace: ~/warp-workspace
```

### 2. Avvia l'app Flutter
```bash
# In un altro terminale
flutter run
```

### 3. Prova i comandi!
Nell'app, ora puoi eseguire comandi direttamente sul tuo sistema:

```bash
# Comandi di sistema
ls -la
pwd
node --version
python3 --version

# AI Chat
/ai "Come creo un server Express?"

# Agent autonomo (quando hai crediti AI)
/agent "Crea una simple React app"
```

## 📁 Workspace

La Local Mode crea automaticamente una directory di lavoro:
- **Percorso**: `~/warp-workspace` (nella tua home directory)
- **Contenuti**: I progetti e file che crei nell'app
- **Sicurezza**: Accesso limitato per proteggere il sistema

## ⚡ Vantaggi Local Mode

### ✅ **Pro:**
- **Setup istantaneo** - Non serve Docker
- **Performance massima** - Niente overhead container  
- **Tool completi** - Accesso a tutto il tuo sistema
- **File persistenti** - I progetti restano sul Mac
- **AI Agent** - Funziona se hai API keys configurate

### ⚠️ **Limitazioni:**
- **Sicurezza**: I comandi girano direttamente sul tuo sistema
- **Dipendenze**: Devi avere Node.js, Python, ecc. installati localmente
- **Portabilità**: L'ambiente dipende dal tuo setup di sistema

## 🔐 Sicurezza

La Local Mode include protezioni di base:
- 🛡️ **Directory limits** - Non può uscire da workspace sicure
- ⏱️ **Timeout** - I processi non possono girare indefinitamente  
- 🚫 **Command filtering** - Blocca comandi pericolosi di sistema
- 📝 **Logging** - Traccia tutti i comandi eseguiti

## 🛠️ Tools Disponibili

La Local Mode può utilizzare tutto quello che hai installato:

### **Linguaggi:**
- 🟢 **Node.js & npm** (se installati)
- 🐍 **Python 3** (se installato)
- 📱 **Flutter** (se installato)
- 🎯 **Go, Rust, Java** (se installati)

### **Tools:**
- 📦 **Git** (se installato)
- 📝 **Editor CLI** (vim, nano)
- 🧰 **System utilities** (curl, wget, ecc.)

## 🤖 AI Agent in Local Mode

L'AI Agent funziona perfettamente in Local Mode:

```bash
# Esempi di task che l'Agent può fare localmente:
/agent "Setup un progetto Node.js con Express"
/agent "Crea una simple HTML page con CSS"
/agent "Installa le dipendenze per un progetto React"
```

L'AI eseguirà i comandi direttamente sul tuo sistema!

## 🔄 Passare tra Docker e Local Mode

### **Usa Docker Mode quando:**
- Vuoi un ambiente isolato e pulito
- Stai testando configurazioni specifiche
- Lavori su progetti che richiedono setup complessi

### **Usa Local Mode quando:**
- Vuoi setup veloce senza Docker
- Hai già un ambiente di sviluppo configurato
- Preferisci lavorare direttamente sui tuoi file

## 📊 Comandi Utili

```bash
# Backend
npm run start    # Docker mode (richiede Docker)  
npm run local    # Local mode (no Docker)
npm run dev      # Development con nodemon

# Test quick
curl http://localhost:3001/health
```

## 🐛 Troubleshooting

### **"Command not found"**
→ Assicurati di avere il tool installato sul tuo sistema

### **"Permission denied"**
→ Il comando sta cercando di accedere a directory protette

### **"AI Agent not available"** 
→ Configura almeno una API key nel file .env

### **Port già in uso**
→ Cambia porta con `PORT=3002 npm run local`

---

**La Local Mode ti dà la massima flessibilità per sviluppare con l'AI direttamente sul tuo sistema! 🚀**