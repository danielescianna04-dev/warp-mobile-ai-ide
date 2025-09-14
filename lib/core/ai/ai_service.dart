import 'dart:async';

/// Enum defining supported AI providers
enum AIProvider {
  openai,
  claude,
  gemini,
  onDevice,
}

/// AI model capabilities
enum AICapability {
  codeGeneration,
  codeExplanation,
  debugging,
  refactoring,
  documentation,
  testing,
}

/// AI response with metadata
class AIResponse {
  final String content;
  final String model;
  final int tokensUsed;
  final Duration responseTime;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.content,
    required this.model,
    required this.tokensUsed,
    required this.responseTime,
    this.metadata,
  });
}

/// Code context for AI operations
class CodeContext {
  final String? currentFile;
  final String? selectedCode;
  final String? language;
  final Map<String, String>? projectFiles;
  final String? errorMessage;

  const CodeContext({
    this.currentFile,
    this.selectedCode,
    this.language,
    this.projectFiles,
    this.errorMessage,
  });
}

/// Abstract AI service interface
abstract class AIService {
  /// Get the AI provider identifier
  AIProvider get provider;

  /// Get supported capabilities
  Set<AICapability> get capabilities;

  /// Check if the service is available/authenticated
  Future<bool> get isAvailable;

  /// Generate code based on prompt and context
  Future<AIResponse> generateCode(
    String prompt,
    CodeContext context,
  );

  /// Explain code functionality
  Future<AIResponse> explainCode(
    String code,
    CodeContext context,
  );

  /// Debug code and suggest fixes
  Future<AIResponse> debugCode(
    String code,
    String error,
    CodeContext context,
  );

  /// Refactor code with improvements
  Future<AIResponse> refactorCode(
    String code,
    String instructions,
    CodeContext context,
  );

  /// Generate documentation for code
  Future<AIResponse> generateDocumentation(
    String code,
    CodeContext context,
  );

  /// Generate unit tests
  Future<AIResponse> generateTests(
    String code,
    CodeContext context,
  );

  /// Stream completion for real-time suggestions
  Stream<String> streamCompletion(
    String prompt,
    CodeContext context,
  );

  /// Get code completions/suggestions
  Future<List<String>> getCompletions(
    String code,
    int cursorPosition,
    CodeContext context,
  );

  /// Chat with AI assistant
  Future<AIResponse> chat(
    String message,
    List<String> conversationHistory,
    CodeContext context,
  );

  /// Configure service settings
  Future<void> configure(Map<String, dynamic> settings);

  /// Dispose resources
  Future<void> dispose();
}

/// Exception thrown by AI services
class AIServiceException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic originalError;

  const AIServiceException(
    this.message, {
    this.errorCode,
    this.originalError,
  });

  @override
  String toString() => 'AIServiceException: $message';
}

/// AI service factory
class AIServiceFactory {
  static final Map<AIProvider, AIService Function()> _factories = {};
  static AIService? _currentService;

  /// Register an AI service implementation
  static void register(AIProvider provider, AIService Function() factory) {
    _factories[provider] = factory;
  }

  /// Create AI service instance
  static AIService create(AIProvider provider) {
    final factory = _factories[provider];
    if (factory == null) {
      throw AIServiceException(
        'No factory registered for provider: $provider',
      );
    }
    return factory();
  }

  /// Get or create current AI service
  static AIService getCurrent(AIProvider provider) {
    if (_currentService?.provider != provider) {
      _currentService?.dispose();
      _currentService = create(provider);
    }
    return _currentService!;
  }

  /// Get available providers
  static List<AIProvider> getAvailableProviders() {
    return _factories.keys.toList();
  }

  /// Dispose current service
  static Future<void> disposeCurrent() async {
    await _currentService?.dispose();
    _currentService = null;
  }
}