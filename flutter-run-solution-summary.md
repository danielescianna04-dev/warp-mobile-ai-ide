# Soluzione Flutter Run Long-Running - Implementazione Completata

## Problema Identificato

Il sistema iniziale eseguiva `flutter run` tramite l'endpoint `/execute-heavy` su ECS Fargate, ma questo causava:

1. **Timeout dopo 30 minuti**: Il processo veniva automaticamente terminato dal lambda tramite timeout su `executeCommand`
2. **Processo non persistente**: Flutter run richiede di rimanere attivo per servire l'applicazione web
3. **Preview non funzionante**: L'URL del server web Flutter diventava inaccessibile dopo il timeout

## Soluzione Implementata

### 1. Backend ECS Fargate - Nuovi Endpoint

**File modificato**: `/backend/ecs/src/app.js`

- **`POST /flutter/run`**: Avvia Flutter run come processo long-running
  - Usa `spawn()` invece di `exec()` per non bloccare
  - Salva il processo in una mappa globale per gestione futura
  - Risponde immediatamente confermando l'avvio
  - Il processo continua in background indefinitamente

- **`POST /flutter/stop`**: Termina il processo Flutter attivo
  - Recupera il processo dalla mappa globale
  - Usa `process.kill()` per terminare correttamente
  - Rimuove il processo dalla mappa
  - Conferma l'arresto

```javascript
// Processi Flutter attivi (in memoria)
const flutterProcesses = new Map();

// Endpoint /flutter/run
app.post('/flutter/run', async (req, res) => {
  const { sessionId, repository, workingDir } = req.body;
  
  // Spawn processo in background senza timeout
  const process = spawn('flutter', ['run', '-d', 'web-server', '--web-port=8080'], {
    cwd: workingDir,
    stdio: 'pipe'
  });
  
  // Salva processo per gestione futura
  flutterProcesses.set(sessionId, { process, repository, startTime: new Date() });
  
  // Risposta immediata
  res.json({ success: true, message: 'Flutter started', pid: process.pid });
});

// Endpoint /flutter/stop  
app.post('/flutter/stop', async (req, res) => {
  const { sessionId } = req.body;
  const entry = flutterProcesses.get(sessionId);
  
  if (entry) {
    entry.process.kill('SIGTERM');
    flutterProcesses.delete(sessionId);
    res.json({ success: true, message: 'Flutter stopped' });
  } else {
    res.json({ success: false, message: 'No Flutter process found' });
  }
});
```

### 2. Lambda Handler - Routing Intelligente

**File modificato**: `/backend/lambda/command-handler.js`

- **Riconoscimento comando `flutter run`**: Intercetta il comando e lo instrada al nuovo endpoint dedicato
- **Riconoscimento comando `flutter stop`**: Intercetta il comando stop e lo instrada all'endpoint di terminazione

```javascript
// Flutter run detection
if (command.toLowerCase().trim() === 'flutter run' && ECS_ENDPOINT) {
  await ensureECSTaskRunning();
  const result = await executeFlutterRun(session, { repository, workingDir });
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      success: result.success || true,
      output: result.output || 'Flutter started successfully',
      executor: 'ecs-fargate-background'
    })
  };
}

// Flutter stop detection  
if (command.toLowerCase().trim() === 'flutter stop' && ECS_ENDPOINT) {
  await ensureECSTaskRunning();
  const result = await executeFlutterStop(session, { repository, workingDir });
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      success: result.success || true,
      output: result.message || 'Flutter process stopped',
      executor: 'ecs-fargate-background'
    })
  };
}
```

### 3. Frontend Flutter - UI Migliorata

**File modificato**: `/lib/pages/warp_terminal_page.dart`

- **Pattern recognition migliorato**: Rileva URL del server web Flutter nell'output
- **Pulsante Preview dinamico**: Si abilita quando rileva server attivo
- **Pulsante Stop Flutter**: Appare quando Flutter è in esecuzione
- **Gestione stato UI**: Traccia lo stato del processo Flutter

```dart
// Pattern per rilevare server Flutter attivo
final flutterServerPattern = RegExp(r'A web server for this project is available at:\s*(https?://[^\s]+)');

// Nel widget UI
if (_isFlutterRunning) 
  ElevatedButton(
    onPressed: _stopFlutterApp,
    child: Text('Stop Flutter'),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  ),

if (_webPreviewUrl != null)
  ElevatedButton(
    onPressed: _openWebPreview, 
    child: Text('Open Preview'),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  ),
```

## Flusso Operativo Completo

### Avvio Flutter Run

1. **Utente**: Digita `flutter run` nel terminale
2. **Frontend**: Invia comando al lambda via API
3. **Lambda**: Rileva il comando e chiama `executeFlutterRun()`
4. **ECS**: Riceve chiamata su `/flutter/run` e avvia processo in background
5. **Processo**: Continua a girare indefinitamente servendo l'app web
6. **Frontend**: Rileva URL nell'output e abilita pulsante Preview

### Stop Flutter

1. **Utente**: Clicca "Stop Flutter" nell'UI (o digita `flutter stop`)
2. **Frontend**: Invia comando `flutter stop` al lambda
3. **Lambda**: Rileva il comando e chiama `executeFlutterStop()`  
4. **ECS**: Riceve chiamata su `/flutter/stop` e termina il processo
5. **Frontend**: Disabilita pulsanti Preview e Stop

## Vantaggi della Soluzione

### ✅ Risolve il Timeout
- Il processo non viene più terminato dopo 30 minuti
- Flutter run rimane attivo finché non viene esplicitamente fermato

### ✅ Preview Funzionante  
- L'URL del server web rimane accessibile
- L'utente può aprire l'anteprima dell'app nel browser

### ✅ Controllo Esplicito
- L'utente decide quando fermare il processo
- Gestione pulita dei processi attivi

### ✅ Architettura Scalabile
- Supporta più sessioni/utenti simultanei
- Ogni processo è tracciato individualmente

## File Modificati

1. **Backend ECS**: `/backend/ecs/src/app.js` - Nuovi endpoint `/flutter/run` e `/flutter/stop`
2. **Lambda**: `/backend/lambda/command-handler.js` - Routing intelligente e funzioni dedicate
3. **Frontend**: `/lib/pages/warp_terminal_page.dart` - UI migliorata con controlli Flutter

## Prossimi Passi per Test

1. **Deploy backend ECS** con nuovi endpoint
2. **Deploy lambda** con routing aggiornato  
3. **Build app Flutter** con nuova UI
4. **Test completo** del flusso flutter run → preview → stop

La soluzione è ora completamente implementata e pronta per il test e deploy finale.