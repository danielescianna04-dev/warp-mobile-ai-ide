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
You are working on a project: $repoName

You have access to these tools:
- readFile(filePath): read any file in the project
- writeFile(filePath, content): create/modify files
- listFiles(directory): list directory contents
- executeCommand(command): run terminal commands

When the user asks to do something (like "run the app", "build", etc):
1. First check what type of project it is (look for pubspec.yaml, package.json, etc)
2. Use the appropriate command automatically
3. Don't ask the user for obvious information you can discover yourself

Be proactive and autonomous!
''';
    }
    
    final fileList = analysis.missingFiles
        .map((f) => '- ${f.path} (${f.reason})')
        .join('\n');
    
    return '''
You are working on a project: $repoName

IMPORTANT: This project has missing configuration files that were gitignored:

$fileList

These files have been created as empty placeholders or from templates.

You have access to these tools:
- readFile(filePath): read any file in the project
- writeFile(filePath, content): create/modify files  
- listFiles(directory): list directory contents
- executeCommand(command): run terminal commands

When the user asks to do something:
1. Use readFile to check project structure (pubspec.yaml, package.json, etc)
2. Determine the correct commands automatically
3. Execute them without asking for obvious information
4. If you need configuration values (API keys, etc), then ask the user

Be proactive and autonomous! Don't ask "what command should I run?" - figure it out yourself.
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
