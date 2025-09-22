# 🚨 PROBLEMA CRITICO: Flutter Run Process Management

## ⚠️ Il Problema che hai Identificato

**SÌ, hai assolutamente ragione!** C'è un **GRAVE PROBLEMA** nel sistema attuale:

### ❌ **Cosa Succede Ora (SBAGLIATO)**
```javascript
// Nel /execute-heavy endpoint di ECS:
const result = await executeCommand(actualCommand, actualWorkingDir);

// executeCommand aspetta che il processo finisca:
child.on('close', (code) => {
  resolve({ stdout, stderr, code, executionTime });
});

// Timeout dopo 30 minuti:
setTimeout(() => {
  child.kill('SIGKILL');
  reject(new Error('Command timeout after 30 minutes'));
}, 30 * 60 * 1000);
```

**RISULTATO**: `flutter run` viene **UCCISO** dopo 30 minuti, anche se dovrebbe rimanere in esecuzione indefinitamente!

### ✅ **Cosa DOVREBBE Succedere**

1. **`flutter run` deve rimanere VIVO** fino a quando l'utente non invia un comando `Ctrl+C` o `stop`
2. **Il processo deve essere DETACHED** dal timeout della richiesta HTTP
3. **Deve essere gestito come LONG-RUNNING PROCESS** simile al `/flutter/web/start` endpoint

## 🔧 **La Soluzione Corretta**

### 📂 **Due Approcci Possibili**

#### **Approccio 1: Endpoint Dedicato per Flutter Run**
```javascript
// Aggiungere un nuovo endpoint: /flutter/run
app.post('/flutter/run', async (req, res) => {
  const { repository = 'flutter-app' } = req.body;
  const repoDir = `/tmp/projects/${repository.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
  
  // Check if already running
  if (flutterWebProcesses.has(repository)) {
    return res.json({
      success: true,
      message: 'Flutter app is already running',
      status: 'running'
    });
  }
  
  // Start Flutter run as detached process
  const flutterProcess = spawn('bash', ['-c', `cd ${repoDir} && flutter run -d web-server --web-port=8080`], {
    cwd: repoDir,
    stdio: ['pipe', 'pipe', 'pipe'],
    detached: false // Non detached per poter gestire i segnali
  });
  
  // Store process reference
  flutterWebProcesses.set(repository, {
    process: flutterProcess,
    port: 8080,
    startTime: Date.now()
  });
  
  // Risposta IMMEDIATA (non aspetta che finisca)
  res.json({
    success: true,
    message: 'Flutter run started in background',
    webUrl: 'http://localhost:8080',
    repository,
    port: 8080,
    status: 'starting'
  });
  
  // Process management in background
  flutterProcess.on('close', (code) => {
    console.log(`Flutter run for ${repository} exited with code ${code}`);
    flutterWebProcesses.delete(repository);
  });
});
```

#### **Approccio 2: Modificare il Routing nel Lambda**
```javascript
// Nel command-handler.js, detection speciale per flutter run:
if (command.toLowerCase().trim() === 'flutter run' && ECS_ENDPOINT) {
  console.log(`🚀 Detected 'flutter run' - using long-running process endpoint...`);
  
  // Chiamare /flutter/run invece di /execute-heavy
  const result = await callFlutterRunEndpoint(session, { repository, workingDir });
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      success: true,
      output: result.message,
      webUrl: result.webUrl, // CRUCIAL!
      port: result.port,
      executor: 'ecs-fargate-background',
      routing: 'flutter-run-background'
    })
  };
}
```

## 🎯 **La Differenza Fondamentale**

### ❌ **Sistema Attuale (ROTTO)**
```
User -> flutter run -> Lambda -> ECS /execute-heavy 
  -> spawn flutter run -> aspetta 30min -> TIMEOUT -> KILL
```

### ✅ **Sistema Corretto**
```
User -> flutter run -> Lambda -> ECS /flutter/run 
  -> spawn flutter run -> return immediato -> processo VIVO in background
```

## 🛠️ **Implementazione Immediata**

### **Step 1**: Aggiungere endpoint `/flutter/run` al server ECS
### **Step 2**: Modificare Lambda per usare questo endpoint per `flutter run`
### **Step 3**: Aggiungere gestione STOP/KILL del processo
### **Step 4**: Frontend per mostrare stato processo

## 💡 **Gestione Comandi Stop**

```javascript
// Per fermare il processo:
app.post('/flutter/stop', (req, res) => {
  const { repository } = req.body;
  
  if (flutterWebProcesses.has(repository)) {
    const processInfo = flutterWebProcesses.get(repository);
    
    // Send SIGINT (Ctrl+C equivalent)
    processInfo.process.kill('SIGINT');
    
    res.json({
      success: true,
      message: `Flutter process for ${repository} stopped`
    });
  }
});
```

## ⚠️ **Priorità CRITICA**

Questo è un **BUG BLOCKING** perché:
- ❌ `flutter run` non può funzionare correttamente 
- ❌ I web server vengono uccisi dopo 30 minuti
- ❌ L'UX è completamente rotta per lo sviluppo Flutter
- ❌ La preview non può funzionare stabilmente

**QUESTO DEVE ESSERE FIXATO PRIMA** del fix per il parsing dell'URL!

---

**OTTIMA OSSERVAZIONE!** 🎯 Hai identificato il problema fondamentale dell'architettura!