// Fix per Flutter Run - Aggiungere al backend Lambda command-handler.js

// Dopo la linea 495 (Smart routing decision), aggiungere questa logica:

// FLUTTER RUN DETECTION - Specifico per 'flutter run' command
if (command.toLowerCase().trim() === 'flutter run' && ECS_ENDPOINT) {
  console.log(`🚀 Detected 'flutter run' command, checking for web output...`);
  
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
          webUrl: webUrl, // KEY: Questo è quello che manca!
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
    // Fallback to Lambda...
  }
}

// Funzioni helper da aggiungere:

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

// ANCHE: Aggiornare isFlutterWebCommand per includere 'flutter run'
function isFlutterWebCommand(command) {
  if (!command) return false;
  
  const cmdLower = command.toLowerCase().trim();
  
  return (
    // AGGIUNGERE QUESTA LINEA:
    cmdLower === 'flutter run' ||
    
    // ... resto del codice esistente
    cmdLower === 'flutter web dev' || 
    cmdLower === 'start flutter web' ||
    // etc...
  );
}