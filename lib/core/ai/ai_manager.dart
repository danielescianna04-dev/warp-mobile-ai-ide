import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'services/openai_service.dart';
import 'services/claude_service.dart';
import 'services/gemini_service.dart';
import '../../config/aws_config.dart';

/// AI Manager per gestire tutti i servizi AI disponibili
class AIManager {
  static AIManager? _instance;
  static AIManager get instance => _instance ??= AIManager._();
  
  AIManager._();

  bool _initialized = false;
  AIService? _currentService;
  AIProvider _currentProvider = AIProvider.openai;

  /// Mappa dei nomi model user-friendly ai provider
  static const Map<String, AIProvider> modelToProvider = {
    'gpt-4': AIProvider.openai,
    'gpt-3.5-turbo': AIProvider.openai,
    'claude-4-sonnet': AIProvider.claude,
    'claude-3-haiku': AIProvider.claude,
    'gemini-pro': AIProvider.gemini,
    'gemini-1.5-pro': AIProvider.gemini,
  };

  /// Mappa dei provider ai loro modelli disponibili
  static const Map<AIProvider, List<String>> providerModels = {
    AIProvider.openai: ['gpt-4', 'gpt-3.5-turbo'],
    AIProvider.claude: ['claude-4-sonnet', 'claude-3-haiku'],
    AIProvider.gemini: ['gemini-pro', 'gemini-1.5-pro'],
  };

  /// Initializza tutti i servizi AI
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Register service factories
    AIServiceFactory.register(AIProvider.openai, () => OpenAIService());
    AIServiceFactory.register(AIProvider.claude, () => ClaudeService());
    AIServiceFactory.register(AIProvider.gemini, () => GeminiService());
    
    _initialized = true;
    debugPrint('✅ AI services initialized successfully');
  }

  /// Chat con l'AI usando Bedrock backend
  Future<AIResponse> chat(
    String message,
    List<String> conversationHistory, {
    CodeContext? context,
    String? model,
    String? workstationName,
  }) async {
    try {
      final url = '${AWSConfig.apiBaseUrl}/ai/chat';
      final selectedModel = model ?? 'claude-3.5';
      
      final body = {
        'prompt': message,
        'conversationHistory': conversationHistory,
        'model': selectedModel,
      };
      
      if (workstationName != null) {
        body['workstationName'] = workstationName;
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AIResponse(
          content: data['content'] ?? data['message'] ?? 'No response',
          model: data['model'] ?? 'claude-3.5',
          tokensUsed: data['usage']?['total_tokens'] ?? 0,
          responseTime: Duration.zero,
        );
      } else {
        throw Exception('AI request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      return AIResponse(
        content: 'Error: Could not connect to AI service. $e',
        model: 'error',
        tokensUsed: 0,
        responseTime: Duration.zero,
      );
    }
  }

  AIProvider get currentProvider => _currentProvider;

  /// Cambia il modello AI (e provider se necessario)
  Future<void> switchModel(String modelName) async {
    if (!_initialized) await initialize();
    
    final provider = modelToProvider[modelName];
    if (provider == null) {
      throw AIServiceException('Model not supported: $modelName');
    }

    await switchProvider(provider);
  }

  /// Cambia provider AI
  Future<void> switchProvider(AIProvider provider) async {
    if (!_initialized) await initialize();

    if (_currentProvider != provider) {
      await _currentService?.dispose();
      _currentService = null;
    }

    _currentProvider = provider;
    _currentService = AIServiceFactory.getCurrent(provider);
  }

  /// Verifica se un servizio è disponibile
  Future<bool> isServiceAvailable(AIProvider provider) async {
    if (!_initialized) await initialize();

    try {
      final service = AIServiceFactory.create(provider);
      final available = await service.isAvailable;
      await service.dispose();
      return available;
    } catch (e) {
      return false;
    }
  }

  /// Ottieni tutti i servizi disponibili
  Future<List<AIProvider>> getAvailableProviders() async {
    if (!_initialized) await initialize();

    final available = <AIProvider>[];
    
    for (final provider in AIProvider.values) {
      if (provider == AIProvider.onDevice) continue; // Skip on-device per ora
      
      if (await isServiceAvailable(provider)) {
        available.add(provider);
      }
    }
    
    return available;
  }

  /// Ottieni modelli disponibili per un provider
  List<String> getModelsForProvider(AIProvider provider) {
    return providerModels[provider] ?? [];
  }

  /// Ottieni tutti i modelli disponibili
  Future<List<String>> getAvailableModels() async {
    final availableProviders = await getAvailableProviders();
    final models = <String>[];
    
    for (final provider in availableProviders) {
      models.addAll(getModelsForProvider(provider));
    }
    
    return models;
  }

  /// Genera codice usando il servizio corrente
  Future<AIResponse> generateCode(String prompt, {CodeContext? context}) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.generateCode(
      prompt, 
      context ?? const CodeContext(),
    );
  }

  /// Stream completion per risposte in tempo reale
  Stream<String> streamCompletion(String prompt, {CodeContext? context}) async* {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    yield* _currentService!.streamCompletion(
      prompt,
      context ?? const CodeContext(),
    );
  }

  /// Spiega codice
  Future<AIResponse> explainCode(String code, {CodeContext? context}) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.explainCode(
      code,
      context ?? const CodeContext(),
    );
  }

  /// Debug codice
  Future<AIResponse> debugCode(
    String code, 
    String error, 
    {CodeContext? context}
  ) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.debugCode(
      code,
      error,
      context ?? const CodeContext(),
    );
  }

  /// Refactoring codice
  Future<AIResponse> refactorCode(
    String code, 
    String instructions, 
    {CodeContext? context}
  ) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.refactorCode(
      code,
      instructions,
      context ?? const CodeContext(),
    );
  }

  /// Genera documentazione
  Future<AIResponse> generateDocumentation(String code, {CodeContext? context}) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.generateDocumentation(
      code,
      context ?? const CodeContext(),
    );
  }

  /// Genera test
  Future<AIResponse> generateTests(String code, {CodeContext? context}) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.generateTests(
      code,
      context ?? const CodeContext(),
    );
  }

  /// Ottieni completamenti di codice
  Future<List<String>> getCompletions(
    String code, 
    int cursorPosition, 
    {CodeContext? context}
  ) async {
    if (!_initialized) await initialize();
    if (_currentService == null) await switchProvider(_currentProvider);
    
    if (_currentService == null) {
      throw const AIServiceException('No AI service available');
    }
    
    return await _currentService!.getCompletions(
      code,
      cursorPosition,
      context ?? const CodeContext(),
    );
  }

  /// Ottieni informazioni sui provider
  String getProviderName(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.claude:
        return 'Claude';
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.onDevice:
        return 'On-Device';
    }
  }

  /// Ottieni informazioni sui modelli
  String getModelDisplayName(String modelName) {
    switch (modelName) {
      case 'gpt-4':
        return 'GPT-4';
      case 'gpt-3.5-turbo':
        return 'GPT-3.5 Turbo';
      case 'claude-4-sonnet':
        return 'Claude 4 Sonnet';
      case 'claude-3-haiku':
        return 'Claude 3 Haiku';
      case 'gemini-pro':
        return 'Gemini Pro';
      case 'gemini-1.5-pro':
        return 'Gemini 1.5 Pro';
      default:
        return modelName;
    }
  }

  /// Pulisci risorse
  Future<void> dispose() async {
    await _currentService?.dispose();
    await AIServiceFactory.disposeCurrent();
    _currentService = null;
    _initialized = false;
  }
}