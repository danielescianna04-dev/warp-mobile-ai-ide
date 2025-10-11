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
      return '';
    }
    
    final fileList = analysis.missingFiles
        .map((f) => '- ${f.path} (${f.reason})')
        .join('\n');
    
    return '''
IMPORTANT: This project has missing configuration files that were gitignored:

$fileList

These files have been created as empty placeholders or from templates.
The user may need help configuring them. When the chat starts, proactively 
inform the user about these missing files and offer to help configure them.

Be conversational and flexible:
- If user doesn't know what they are, explain simply
- If user asks you to do it, guide them step by step
- If user wants to do it themselves, provide instructions
- If user wants to skip for now, that's fine too

You have access to these tools:
- readFile(path): read file content
- writeFile(path, content): create/modify files
- listFiles(directory): list directory contents
- executeCommand(command): run terminal commands
''';
  }
  
  static Future<String> generateInitialMessage({
    required String userId,
    required String repoName,
  }) async {
    final analysis = await WorkstationService.analyzeWorkspace(
      userId: userId,
      repoName: repoName,
    );
    
    if (!analysis.success || analysis.missingFiles.isEmpty) {
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
