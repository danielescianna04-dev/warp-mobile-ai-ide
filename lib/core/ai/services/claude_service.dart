import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../ai_service.dart';

/// Claude (Anthropic) service implementation
class ClaudeService implements AIService {
  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _model = 'claude-3-sonnet-20240229';
  static const String _version = '2023-06-01';
  
  String? _apiKey;
  http.Client? _client;

  ClaudeService({String? apiKey}) : _apiKey = apiKey {
    _client = http.Client();
  }

  @override
  AIProvider get provider => AIProvider.claude;

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
        'messages',
        method: 'POST',
        body: jsonEncode({
          'model': _model,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hello'}
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
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
  }

  @override
  Future<AIResponse> explainCode(String code, CodeContext context) async {
    final systemPrompt = _buildSystemPrompt('code_explanation', context);
    final userPrompt = 'Please explain this code:\n\n```${context.language ?? ''}\n$code\n```';
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
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
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
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
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
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
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
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
    
    return await _createMessage([
      {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
    ]);
  }

  @override
  Stream<String> streamCompletion(String prompt, CodeContext context) async* {
    final systemPrompt = _buildSystemPrompt('code_generation', context);
    final userPrompt = _buildUserPrompt(prompt, context);
    
    final request = {
      'model': _model,
      'max_tokens': 2000,
      'messages': [
        {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
      ],
      'stream': true,
    };

    final response = await _makeRequest(
      'messages',
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
        if (data == '[DONE]') break;
        
        try {
          final json = jsonDecode(data);
          final delta = json['delta']?['text'];
          if (delta != null) {
            yield delta as String;
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
    final messages = <Map<String, String>>[];
    
    // Add system prompt as first user message
    final systemPrompt = _buildSystemPrompt('chat', context);
    messages.add({'role': 'user', 'content': systemPrompt});
    
    // Add conversation history
    for (int i = 0; i < conversationHistory.length; i++) {
      messages.add({
        'role': i % 2 == 0 ? 'user' : 'assistant',
        'content': conversationHistory[i],
      });
    }
    
    // Add current message
    messages.add({'role': 'user', 'content': message});
    
    return await _createMessage(messages);
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
    
    buffer.writeln('You are Claude, an AI assistant specialized in mobile development and coding.');
    
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

  /// Make HTTP request to Anthropic API
  Future<http.StreamedResponse> _makeRequest(
    String endpoint, {
    String method = 'POST',
    String? body,
    Map<String, String>? headers,
  }) async {
    if (_apiKey == null) {
      throw const AIServiceException('Claude API key not configured');
    }

    final uri = Uri.parse('$_baseUrl/$endpoint');
    final request = http.Request(method, uri);
    
    request.headers.addAll({
      'x-api-key': _apiKey!,
      'anthropic-version': _version,
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

  /// Create message helper
  Future<AIResponse> _createMessage(List<Map<String, String>> messages) async {
    final startTime = DateTime.now();
    
    final request = {
      'model': _model,
      'max_tokens': 2000,
      'messages': messages,
    };

    final response = await _makeRequest(
      'messages',
      body: jsonEncode(request),
      headers: {'Content-Type': 'application/json'},
    );

    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode != 200) {
      final error = jsonDecode(responseBody);
      throw AIServiceException(
        'Claude API error: ${error['error']?['message'] ?? 'Unknown error'}',
        errorCode: error['error']?['type'],
      );
    }

    final jsonResponse = jsonDecode(responseBody);
    final content = jsonResponse['content'][0]['text'] as String;
    final tokensUsed = (jsonResponse['usage']['input_tokens'] as int) +
                     (jsonResponse['usage']['output_tokens'] as int);
    
    return AIResponse(
      content: content,
      model: _model,
      tokensUsed: tokensUsed,
      responseTime: DateTime.now().difference(startTime),
      metadata: {
        'stop_reason': jsonResponse['stop_reason'],
        'usage': jsonResponse['usage'],
      },
    );
  }
}