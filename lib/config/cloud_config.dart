class CloudConfig {
  // 🌐 Production backend URL (sostituisci con il tuo URL Cloud Run)
  static const String productionBackendUrl = 'https://warp-mobile-ai-ide-xxxxx-ew.a.run.app';
  
  // 🏠 Local development URL
  static const String localBackendUrl = 'ws://192.168.0.229:3001';
  
  // 🔧 Environment detection
  static bool get isProduction => 
      const bool.fromEnvironment('dart.vm.product', defaultValue: false);
  
  // 📡 WebSocket URL based on environment
  static String get webSocketUrl {
    if (isProduction) {
      return productionBackendUrl.replaceFirst('https://', 'wss://');
    } else {
      return localBackendUrl;
    }
  }
  
  // 🌐 HTTP URL for REST APIs
  static String get httpUrl {
    if (isProduction) {
      return productionBackendUrl;
    } else {
      return 'http://192.168.0.229:3001';
    }
  }
  
  // 📊 Health check endpoint
  static String get healthCheckUrl => '$httpUrl/health';
  
  // 🤖 AI Agent endpoints
  static String get aiEndpoint => '$httpUrl/ai';
  static String get agentEndpoint => '$httpUrl/agent';
  
  // ⚙️ Configuration flags
  static const Map<String, dynamic> productionConfig = {
    'enableLogging': false,
    'enableDebugMode': false,
    'apiTimeout': 30000,
    'retryAttempts': 3,
    'maxConcurrentConnections': 5,
  };
  
  static const Map<String, dynamic> developmentConfig = {
    'enableLogging': true,
    'enableDebugMode': true,
    'apiTimeout': 10000,
    'retryAttempts': 1,
    'maxConcurrentConnections': 1,
  };
  
  // 🎯 Get current config
  static Map<String, dynamic> get currentConfig => 
      isProduction ? productionConfig : developmentConfig;
}