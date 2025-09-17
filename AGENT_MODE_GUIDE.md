# 🤖 Warp Mobile AI IDE - Agent Mode

## 🌟 Cos'è l'Agent Mode?

L'Agent Mode è la funzionalità più avanzata di Warp Mobile AI IDE: permette all'AI di eseguire **autonomamente** comandi nel container Docker per completare task complessi senza supervisione umana continua.

### ✨ Funzionalità principali:
- **Esecuzione autonoma**: L'AI pianifica ed esegue comandi step-by-step
- **Multi-model support**: OpenAI, Claude, Gemini disponibili  
- **Real-time feedback**: Vedi ogni step dell'AI in tempo reale
- **Fallback intelligente**: Se qualcosa fallisce, l'AI trova soluzioni alternative
- **Safety controls**: Timeout automatici e limitazioni di sicurezza

## 🚀 Setup Rapido

### 1. **Configura le API Keys**

Modifica il file `.env` nella root del progetto:

```bash
# Almeno una di queste chiavi API è necessaria:
OPENAI_API_KEY=sk-your-openai-key-here
ANTHROPIC_API_KEY=sk-ant-your-claude-key-here  
GOOGLE_AI_API_KEY=your-google-ai-key-here
```

**Come ottenerle:**
- **OpenAI**: https://platform.openai.com/api-keys
- **Claude**: https://console.anthropic.com/
- **Gemini**: https://makersuite.google.com/app/apikey

### 2. **Avvia il Backend**

```bash
cd backend
npm install
npm start
```

Dovresti vedere:
```
🤖 AI Agent initialized with X providers
🚀 Terminal Backend Server started
📡 WebSocket server running on ws://localhost:3001
```

### 3. **Avvia l'App Flutter**

```bash
flutter run
```

L'app si connetterà automaticamente al backend Docker.

## 🎯 Come Usare l'Agent Mode

### **Modalità Chat AI Semplice**

Nella terminal dell'app Flutter, puoi usare comandi speciali per interagire con l'AI:

```bash
# Chat con AI (risposta singola)  
/ai "Spiega questo errore: command not found"

# Cambia modello AI
/ai-model claude
/ai-model gpt-4  
/ai-model gemini
```

### **Modalità Agent Autonoma** 🔥

Per task complessi, usa la modalità Agent:

```bash
# L'AI eseguirà autonomamente tutti i passi necessari
/agent "Crea un'app React con routing e una homepage"

# L'AI analizzerà, pianificherà e eseguirà:
# 1. npx create-react-app my-app
# 2. cd my-app  
# 3. npm install react-router-dom
# 4. Creerà i componenti necessari
# 5. Configurerà il routing
# 6. Avvierà il dev server
```

### **Esempi di Task per l'Agent** 🛠️

```bash
# Sviluppo Web
/agent "Crea un portfolio website con React e tailwind"
/agent "Setup di un'API REST con Express e MongoDB"  
/agent "Crea un blog con Next.js e deploy su Vercel"

# Analisi Codice
/agent "Trova e correggi tutti i bug in questo progetto"
/agent "Ottimizza le performance di questa app React"
/agent "Aggiungi test unit a tutte le funzioni"

# DevOps & Deployment  
/agent "Setup CI/CD pipeline con GitHub Actions"
/agent "Dockerizza questa applicazione"
/agent "Deploy su AWS con terraform"

# Data Science
/agent "Analizza questo dataset CSV e crea visualizzazioni"  
/agent "Crea un modello ML per predire vendite"
/agent "Setup ambiente Python con Jupyter per data analysis"
```

## 🎮 Interfaccia Utente

### **Indicatori Visuali** 

Durante l'esecuzione dell'Agent vedrai:

- 🤖 **Agent attivo**: Indicatore che l'AI sta lavorando
- 🔄 **Step in corso**: Quale comando sta eseguendo  
- ⏱️ **Tempo trascorso**: Durata dell'operazione
- 📊 **Progress**: Quanti step completati
- ✅/❌ **Risultati**: Success/failure di ogni step

### **Controlli Disponibili**

- **Pause/Resume**: Ferma temporaneamente l'agent
- **Stop**: Termina l'esecuzione corrente  
- **Provider Switch**: Cambia modello AI al volo
- **Log View**: Vedi dettagli tecnici di ogni step

## 🛡️ Sicurezza & Limitazioni

### **Safety Controls Automatici**
- **Timeout**: 5 minuti max per task
- **Max iterations**: Massimo 10 step per task  
- **Command filtering**: Comandi dannosi bloccati
- **Resource limits**: 2GB RAM, CPU limitata
- **Container isolation**: Tutto eseguito in Docker sandbox

### **Limitazioni Attuali**
- ❌ Non può accedere a file fuori dal container
- ❌ Non può fare chiamate di rete esterne non autorizzate
- ❌ Non può modificare il sistema host
- ❌ Comandi interattivi (vi, nano) potrebbero non funzionare perfettamente

## 🔧 Configurazione Avanzata

### **Personalizzazione Agent**

Nel file `.env` puoi configurare:

```bash
# Agent Configuration
AGENT_MODE_ENABLED=true
AGENT_MAX_ITERATIONS=15        # Più step consentiti
AGENT_TIMEOUT_SECONDS=600      # 10 minuti timeout  
AGENT_AUTO_APPROVE=false       # Richiede conferma per ogni step
DEBUG_AI=true                  # Logging dettagliato
```

### **Modelli AI Raccomandati**

**Per coding tasks:**
- 🥇 **Claude 4 Sonnet**: Migliore per coding complesso  
- 🥈 **GPT-4**: Ottimo balance qualità/velocità
- 🥉 **Gemini Pro**: Buono per task semplici

**Per analisi dati:**
- 🥇 **GPT-4**: Eccellente per data science
- 🥈 **Claude 4**: Ottimo per spiegazioni dettagliate

## 🐛 Troubleshooting

### **Agent Non Risponde**
```bash
# Controlla connessione backend
curl http://localhost:3001/health

# Verifica API keys
grep -E "OPENAI_API_KEY|ANTHROPIC_API_KEY" .env

# Restart completo
pkill -f "node server.js" 
npm start
```

### **Errori Comuni**

**"AI Agent not available"**  
→ Controlla che almeno una API key sia configurata

**"WebSocket connection failed"**  
→ Assicurati che il backend sia in ascolto su porta 3001

**"Command execution failed"**  
→ L'AI proverà automaticamente approcci alternativi

## 🎉 Esempi Pratici

### **Creare un E-commerce**
```bash
/agent "Crea un e-commerce completo con React, carrello shopping, checkout e pagamenti stripe"
```

L'AI eseguirà ~15-20 step automaticamente:
1. Setup progetto React  
2. Installa dipendenze (stripe, router, etc)
3. Crea componenti (ProductList, Cart, Checkout) 
4. Setup routing  
5. Integra Stripe
6. Aggiunge styling
7. Testa funzionalità  
8. Avvia dev server

### **Setup Development Environment**  
```bash
/agent "Setup ambiente completo per development: Node.js, Python, Docker, Git configurato con SSH keys"
```

### **Analisi Performance**
```bash  
/agent "Analizza performance di questa app React, trova bottlenecks, implementa lazy loading e code splitting"
```

## 🔮 Roadmap Future

**Coming Soon:**
- 🎨 **UI Drag & Drop**: Interfaccia visual per creare task
- 🔗 **GitHub Integration**: Deploy automatico su repository
- 📱 **Mobile Preview**: Preview app direttamente su device  
- 🧠 **Memory**: L'AI ricorda conversazioni precedenti
- 👥 **Team Collaboration**: Condivisione agent tra team
- 🚀 **One-click Deploy**: Deploy automatico su cloud providers

---

## 💡 Tips & Tricks

1. **Sii specifico**: "Crea una todo app" vs "Crea una todo app con React, TypeScript, localStorage e dark mode"

2. **Usa context**: L'AI vede la directory corrente e file esistenti

3. **Monitora i logs**: Nel terminale backend vedrai ogni step dell'AI

4. **Prova provider diversi**: Claude è spesso migliore per coding, GPT-4 per problem solving

5. **Task incrementali**: Se un task è troppo complesso, dividilo in sub-task

**Happy Coding with AI! 🚀🤖**