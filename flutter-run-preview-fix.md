# 🔧 Fix per Flutter Run Preview

## 🎯 Problema
Quando si esegue `flutter run` su una repository GitHub Flutter, l'occhio per la preview non si attiva perché il `webUrl` non viene restituito dal backend.

## 📋 Soluzione

### 1. **Backend Fix - command-handler.js**

Aggiungere dopo la linea 492 (prima del "Smart routing decision"):

```javascript
// FLUTTER RUN SPECIFIC DETECTION
if (command.toLowerCase().trim() === 'flutter run' && ECS_ENDPOINT) {
  console.log(`🚀 Detected 'flutter run' command, executing with web detection...`);
  
  try {
    // Ensure ECS task is running
    await ensureECSTaskRunning();
    
    // Execute on ECS and monitor output for web server
    const result = await executeOnECS(command, session, { repository, workingDir });
    
    // Parse output for Flutter web server URL
    const webUrl = extractFlutterWebUrl(result.output);
    
    if (webUrl) {
      console.log(`✅ Flutter run detected web server at: ${webUrl}`);
      return {
        statusCode: 200,
        headers: { ...headers, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: result.exitCode === 0,
          output: result.output,
          webUrl: webUrl, // CRUCIAL: This enables preview button!
          port: extractPortFromUrl(webUrl) || 8080,
          repository: repository || 'flutter-app',
          executor: 'ecs-fargate',
          routing: 'flutter-run-web-detected'
        })
      };
    }
    
    // No web URL found, return normal result
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: result.exitCode === 0,
        output: result.output,
        executor: 'ecs-fargate',
        routing: 'flutter-run-normal'
      })
    };
    
  } catch (ecsError) {
    console.error('⚠️  Flutter run ECS execution failed:', ecsError.message);
    // Continue to normal smart routing...
  }
}
```

### 2. **Aggiungere funzioni helper alla fine del file:**

```javascript
function extractFlutterWebUrl(output) {
  const patterns = [
    // Flutter web server patterns
    /flutter web server.*?(https?:\/\/[^\s]+)/i,
    /serving at.*?(https?:\/\/[^\s]+)/i,
    /web server started.*?(https?:\/\/[^\s]+)/i,
    /application available.*?(https?:\/\/[^\s]+)/i,
    
    // Standard localhost patterns per Flutter
    /(https?:\/\/localhost:\d+)/i,
    /(https?:\/\/127\.0\.0\.1:\d+)/i,
    /(https?:\/\/0\.0\.0\.0:\d+)/i,
    
    // Flutter-specific output patterns
    /A web server for Flutter web application.*?(https?:\/\/[^\s]+)/i,
    /Starting\s+dev\s+server.*?(https?:\/\/[^\s]+)/i,
  ];
  
  for (const pattern of patterns) {
    const match = output.match(pattern);
    if (match && match[1]) {
      return match[1].trim();
    }
  }
  
  return null;
}

function extractPortFromUrl(url) {
  const match = url.match(/:(\d+)/);
  return match ? parseInt(match[1]) : null;
}
```

### 3. **Flutter Web Helper Update**

Nel file `flutter-web-helper.js`, aggiornare `isFlutterWebCommand`:

```javascript
function isFlutterWebCommand(command) {
  if (!command) return false;
  
  const cmdLower = command.toLowerCase().trim();
  
  return (
    // AGGIUNGERE QUESTA LINEA:
    cmdLower === 'flutter run' ||
    
    // ... resto del codice esistente
    cmdLower === 'flutter web dev' || 
    cmdLower === 'start flutter web' ||
    cmdLower === 'flutter start web' ||
    cmdLower === 'flutter web start' ||
    
    cmdLower.includes('flutter run -d web') ||
    cmdLower.includes('flutter run --web') ||
    cmdLower.includes('flutter run --device=web') ||
    cmdLower.includes('flutter run -d chrome') ||
    
    (cmdLower.startsWith('flutter') && cmdLower.includes('--web-port'))
  );
}
```

### 4. **Frontend Fix - TerminalService.dart**

Il codice esistente già gestisce il `webUrl` correttamente:

```dart
// Handle Flutter web app URL from backend
print('🔍 Debug: Full response data: $responseData');
if (responseData['webUrl'] != null) {
  final webUrl = responseData['webUrl'].toString();
  final port = responseData['port']?.toString() ?? '8080';
  _exposedPorts['$port/tcp'] = webUrl;
  print('🚀 Flutter web app detected at: $webUrl');
  print('🔍 Debug: Updated exposed ports: $_exposedPorts');
} else {
  print('⚠️ Debug: No webUrl found in response');
}
```

### 5. **Miglioramento Pattern Detection - warp_terminal_page.dart**

Nel metodo `_checkForRunningApp`, aggiungere più pattern per Flutter:

```dart
final patterns = [
  // AGGIUNGERE QUESTI PATTERN FLUTTER:
  RegExp(r'Flutter\s+web\s+server.*?started.*?(https?://[^\s]+)', caseSensitive: false),
  RegExp(r'Application\s+started.*?(https?://[^\s]+)', caseSensitive: false),
  RegExp(r'Dev\s+server\s+running.*?(https?://[^\s]+)', caseSensitive: false),
  
  // ... pattern esistenti
  RegExp(r'Flutter web server.*http://[^\s]+', caseSensitive: false),
  RegExp(r'Serving at.*http://[^\s]+', caseSensitive: false),
  // etc...
];
```

## 🧪 Testing

Per testare il fix:

1. **Seleziona una repository Flutter** dalla sidebar GitHub
2. **Esegui `flutter run`** nel terminale
3. **Il backend dovrebbe**:
   - Rilevare il comando come Flutter
   - Eseguirlo su ECS Fargate
   - Parsare l'output per URL web
   - Restituire `webUrl` nella response
4. **Il frontend dovrebbe**:
   - Ricevere `webUrl` nella response
   - Aggiornare `_exposedPorts`
   - Attivare l'occhio preview (non più grigio)
   - Permettere click per aprire preview

## 🔍 Debug

Per debug, controllare i log:

```bash
# Backend logs:
🚀 Detected 'flutter run' command, executing with web detection...
✅ Flutter run detected web server at: https://...

# Frontend logs:
🚀 Flutter web app detected at: https://...
🔍 Debug: Updated exposed ports: {...}
```

## 🎯 Risultato Atteso

- ✅ Il comando `flutter run` viene rilevato
- ✅ L'execution avviene su ECS Fargate 
- ✅ Il `webUrl` viene estratto dall'output
- ✅ L'icona preview si attiva (da grigia a colorata)
- ✅ Cliccando l'occhio si apre la preview dell'app Flutter