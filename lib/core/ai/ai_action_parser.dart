import 'ai_tool_handler.dart';

class AIAction {
  final String tool;
  final List<String> parameters;
  
  AIAction({required this.tool, required this.parameters});
}

class AIActionParser {
  static final RegExp _actionRegex = RegExp(r'\[ACTION:([^:]+):([^\]]+)\]');
  
  static List<AIAction> parseActions(String text) {
    final matches = _actionRegex.allMatches(text);
    return matches.map((match) {
      final tool = match.group(1)!;
      final paramsStr = match.group(2)!;
      final parameters = paramsStr.split(':');
      return AIAction(tool: tool, parameters: parameters);
    }).toList();
  }
  
  static String removeActions(String text) {
    return text.replaceAll(_actionRegex, '').trim();
  }
  
  static Future<String> executeActions({
    required String aiResponse,
    required String userId,
    required String repoName,
  }) async {
    final actions = parseActions(aiResponse);
    if (actions.isEmpty) return aiResponse;
    
    final results = <String>[];
    
    for (final action in actions) {
      try {
        final params = <String, dynamic>{};
        
        switch (action.tool) {
          case 'readFile':
            params['filePath'] = action.parameters[0];
            break;
          case 'writeFile':
            params['filePath'] = action.parameters[0];
            params['content'] = action.parameters.length > 1 
                ? action.parameters.sublist(1).join(':') 
                : '';
            break;
          case 'listFiles':
            params['directory'] = action.parameters.isNotEmpty 
                ? action.parameters[0] 
                : '.';
            break;
          case 'executeCommand':
            params['command'] = action.parameters.join(':');
            break;
        }
        
        final result = await AIToolHandler.handleToolCall(
          toolName: action.tool,
          parameters: params,
          userId: userId,
          repoName: repoName,
        );
        
        results.add('✓ ${action.tool}: $result');
      } catch (e) {
        results.add('✗ ${action.tool}: $e');
      }
    }
    
    final cleanResponse = removeActions(aiResponse);
    final actionResults = results.join('\n');
    
    return '$cleanResponse\n\n$actionResults';
  }
}
