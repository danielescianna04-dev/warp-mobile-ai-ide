import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../ai_service.dart';

/// Gemini (Google AI) service implementation
class GeminiService implements AIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-1.5-pro-latest';
  
  String? _apiKey;
  http.Client? _client;

  GeminiService({String? apiKey}) : _apiKey = apiKey {
    _client = http.Client();
  }

  @override
  AIProvider get provider => AIProvider.gemini;

  @override
  Set<AICapability> get capabilities => {
    AICapability.codeGeneration,
    AICapability.codeExplanation,
    AICapability.debugging,
    AICapability.refactoring,
    AICapability.documentation,
    AICapability.testing,
  };

  @override
  Future<bool> get isAvailable async {
    if (_apiKey == null) return false;
    
    try {
      final response = await _makeRequest(
        'models/$_model:generateContent',
        method: 'POST',
        body: jsonEncode({
          'contents': [
            {'parts': [{'text': 'Hello'}]}
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AIResponse> generateCode(String prompt, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('code_generation', context);
    final userPrompt = _buildUserPrompt(prompt, context);
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Future<AIResponse> explainCode(String code, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('code_explanation', context);
    final userPrompt = 'Please explain this code:\n\n```${context.language ?? ''}\n$code\n```';
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Future<AIResponse> debugCode(String code, String error, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('debugging', context);
    final userPrompt = '''
Please help debug this code:

Code:
```${context.language ?? ''}
$code
```

Error:
```
$error
```

Please provide a fix and explanation.
''';
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Future<AIResponse> refactorCode(String code, String instructions, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('refactoring', context);
    final userPrompt = '''
Please refactor this code based on the instructions:

Instructions: $instructions

Code:
```${context.language ?? ''}
$code
```
''';
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Future<AIResponse> generateDocumentation(String code, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('documentation', context);
    final userPrompt = '''
Please generate documentation for this code:

```${context.language ?? ''}
$code
```
''';
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Future<AIResponse> generateTests(String code, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('testing', context);
    final userPrompt = '''
Please generate unit tests for this code:

```${context.language ?? ''}
$code
```
''';
    
    return await _generateContent('$systemPrompt\n\n$userPrompt');
  }

  @override
  Stream<String> streamCompletion(String prompt, CodeContext context) async* {
    final systemPrompt = _buildSystemPrompt('code_generation', context);
    final userPrompt = _buildUserPrompt(prompt, context);
    
    final request = {
      'contents': [
        {'parts': [{'text': '$systemPrompt\n\n$userPrompt'}]}
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 2000,
      }
    };

    final response = await _makeRequest(
      'models/$_model:streamGenerateContent',
      method: 'POST',
      body: jsonEncode(request),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw AIServiceException('Stream completion failed: $errorBody');
    }

    await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data.trim().isEmpty) continue;
        
        try {
          final json = jsonDecode(data);
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            if (content != null) {
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'];
                if (text != null) {
                  yield text as String;
                }
              }
            }
          }
        } catch (e) {
          // Skip malformed chunks
          continue;
        }
      }
    }
  }

  @override
  Future<List<String>> getCompletions(String code, int cursorPosition, CodeContext context) async {
    final beforeCursor = code.substring(0, cursorPosition);
    final afterCursor = code.substring(cursorPosition);
    
    final prompt = '''
Complete this code at the cursor position (marked with |):

```${context.language ?? ''}
$beforeCursor|$afterCursor
```

Provide multiple completion options.
''';

    final response = await generateCode(prompt, context);
    
    // Parse multiple completions from the response
    final completions = <String>[];
    final lines = response.content.split('\n');
    
    for (final line in lines) {
      if (line.trim().isNotEmpty && !line.startsWith('//') && !line.startsWith('*')) {
        completions.add(line.trim());
      }
      if (completions.length >= 5) break; // Limit to 5 completions
    }
    
    return completions;
  }

  @override
  Future<AIResponse> chat(String message, List<String> conversationHistory, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('chat', context);
    
    // Build conversation content
    final buffer = StringBuffer();
    buffer.writeln(systemPrompt);
    buffer.writeln();
    
    // Add conversation history
    for (int i = 0; i < conversationHistory.length; i++) {
      final role = i % 2 == 0 ? 'User' : 'Assistant';
      buffer.writeln('$role: ${conversationHistory[i]}');
    }
    
    // Add current message
    buffer.writeln('User: $message');
    buffer.writeln('Assistant: ');
    
    return await _generateContent(buffer.toString());
  }

  @override
  Future<void> configure(Map<String, dynamic> settings) async {
    _apiKey = settings['apiKey'] as String?;
  }

  @override
  Future<void> dispose() async {
    _client?.close();
    _client = null;
  }

  /// Build system prompt based on context and task
  String _buildSystemPrompt(String task, CodeContext context) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are Gemini, a helpful AI assistant specialized in mobile development and coding.');
    
    switch (task) {
      case 'code_generation':
        buffer.writeln('Generate clean, efficient, and well-documented code.');
        break;
      case 'code_explanation':
        buffer.writeln('Explain code clearly and concisely for mobile developers.');
        break;
      case 'debugging':
        buffer.writeln('Debug code by identifying issues and providing clear fixes.');
        break;
      case 'refactoring':
        buffer.writeln('Refactor code to improve readability, performance, and maintainability.');
        break;
      case 'documentation':
        buffer.writeln('Generate comprehensive documentation following best practices.');
        break;
      case 'testing':
        buffer.writeln('Generate thorough unit tests with good coverage.');
        break;
      case 'chat':
        buffer.writeln('Assist with coding questions and mobile development.');
        break;
    }
    
    if (context.language != null) {
      buffer.writeln('Programming language: ${context.language}');
    }
    
    if (context.currentFile != null) {
      buffer.writeln('Current file: ${context.currentFile}');
    }
    
    buffer.writeln('Focus on mobile-first development practices.');
    
    return buffer.toString();
  }

  /// Build user prompt with context
  String _buildUserPrompt(String prompt, CodeContext context) {
    final buffer = StringBuffer();
    
    if (context.selectedCode != null) {
      buffer.writeln('Selected code context:');
      buffer.writeln('```${context.language ?? ''}');
      buffer.writeln(context.selectedCode);
      buffer.writeln('```\n');
    }
    
    buffer.writeln(prompt);
    
    return buffer.toString();
  }

  /// Make HTTP request to Gemini API
  Future<http.StreamedResponse> _makeRequest(
    String endpoint, {
    String method = 'POST',
    String? body,
    Map<String, String>? headers,
  }) async {
    if (_apiKey == null) {
      throw const AIServiceException('Gemini API key not configured');
    }

    final uri = Uri.parse('$_baseUrl/$endpoint?key=$_apiKey');
    final request = http.Request(method, uri);
    
    request.headers.addAll({
      'Content-Type': 'application/json',
      ...?headers,
    });
    
    if (body != null) {
      request.body = body;
    }

    try {
      return await _client!.send(request);
    } on SocketException catch (e) {
      throw AIServiceException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw AIServiceException('Request failed: $e', originalError: e);
    }
  }

  /// Generate content helper
  Future<AIResponse> _generateContent(String prompt) async {
    final startTime = DateTime.now();
    
    final request = {
      'contents': [
        {'parts': [{'text': prompt}]}
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 2000,
      }
    };

    final response = await _makeRequest(
      'models/$_model:generateContent',
      body: jsonEncode(request),
      headers: {'Content-Type': 'application/json'},
    );

    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode != 200) {
      final error = jsonDecode(responseBody);
      throw AIServiceException(
        'Gemini API error: ${error['error']?['message'] ?? 'Unknown error'}',
        errorCode: error['error']?['code']?.toString(),
      );
    }

    final jsonResponse = jsonDecode(responseBody);
    final candidates = jsonResponse['candidates'] as List;
    
    if (candidates.isEmpty) {
      throw const AIServiceException('No response generated');
    }
    
    final content = candidates[0]['content']['parts'][0]['text'] as String;
    
    // Gemini doesn't return exact token usage in the same format
    final tokensUsed = content.split(' ').length; // Rough estimation
    
    return AIResponse(
      content: content,
      model: _model,
      tokensUsed: tokensUsed,
      responseTime: DateTime.now().difference(startTime),
      metadata: {
        'finish_reason': candidates[0]['finishReason']?.toString(),
        'safety_ratings': candidates[0]['safetyRatings']?.toString(),
      },
    );
  }
}