import '../workstation/workstation_service.dart';

class AIContextManager {
  static Future<String> generateInitialContext({
    required String userId,
    required String repoName,
  }) async {
    final analysis = await WorkstationService.analyzeWorkspace(
      userId: userId,
      repoName: repoName,
    );
    
    if (!analysis.success || analysis.missingFiles.isEmpty) {
      return '''
You are an autonomous AI agent working on project: $repoName

IMPORTANT: You can execute actions by writing them in this format:
[ACTION:toolName:parameters]

Available actions:
- [ACTION:readFile:path/to/file.txt] - reads a file
- [ACTION:writeFile:path/to/file.txt:content here] - writes to a file
- [ACTION:listFiles:directory/path] - lists directory
- [ACTION:executeCommand:flutter run] - runs a command

When user asks you to do something:
1. DON'T ask for permission or details you can discover yourself
2. Use [ACTION:...] to check project structure
3. Execute the appropriate commands automatically
4. Only ask if you need secret values (API keys, passwords)

Example:
User: "run the app"
You: [ACTION:readFile:pubspec.yaml]
(after seeing it's Flutter)
You: [ACTION:executeCommand:flutter run]
Done! App is starting...

BE AUTONOMOUS! Don't ask "what should I do?" - just do it!
''';
    }
    
    final fileList = analysis.missingFiles
        .map((f) => '- ${f.path} (${f.reason})')
        .join('\n');
    
    return '''
You are an autonomous AI agent working on project: $repoName

Missing configuration files:
$fileList

IMPORTANT: You can execute actions by writing them in this format:
[ACTION:toolName:parameters]

Available actions:
- [ACTION:readFile:path/to/file.txt] - reads a file
- [ACTION:writeFile:path/to/file.txt:content here] - writes to a file  
- [ACTION:listFiles:directory/path] - lists directory
- [ACTION:executeCommand:flutter run] - runs a command

When user asks you to do something:
1. DON'T ask for permission or details
2. Use [ACTION:...] to check what you need
3. Execute commands automatically
4. Create placeholder files if needed
5. Only ask for secret values (API keys)

Example:
User: "populate missing files"
You: [ACTION:writeFile:/android/app/debug:]
[ACTION:writeFile:/android/app/profile:]
[ACTION:writeFile:/android/app/release:]
Done! Created placeholder files.

BE AUTONOMOUS! Just do it!
''';
  }
  
  static Future<String> generateInitialMessage({
    required String userId,
    required String repoName,
    AnalysisResult? cachedAnalysis,
  }) async {
    final analysis = cachedAnalysis ?? await WorkstationService.analyzeWorkspace(
      userId: userId,
      repoName: repoName,
    );
    
    print('📊 Analysis result:');
    print('   success: ${analysis.success}');
    print('   missingFiles count: ${analysis.missingFiles.length}');
    if (analysis.missingFiles.isNotEmpty) {
      print('   files: ${analysis.missingFiles.map((f) => f.path).take(5).join(", ")}');
    }
    
    if (!analysis.success || analysis.missingFiles.isEmpty) {
      print('⚠️ Returning empty message - no missing files or analysis failed');
      return '';
    }
    
    final fileList = analysis.missingFiles
        .map((f) => '• ${f.path}')
        .join('\n');
    
    return '''Ciao! Ho analizzato il progetto $repoName.

⚠️ Ho rilevato alcuni file di configurazione mancanti:

$fileList

Ho creato dei template vuoti per permetterti di compilare il progetto.

Vuoi che ti aiuti a configurarli ora? Oppure preferisci sviluppare prima e configurarli dopo?''';
  }
}
