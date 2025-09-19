/// AWS Configuration for Production Deployment
class AWSConfig {
  // AWS API Gateway Configuration - NEW HYBRID BACKEND
  static const String apiBaseUrl = 'https://o571gs6nb7.execute-api.us-east-1.amazonaws.com/prod';
  static const String wsBaseUrl = 'wss://o571gs6nb7.execute-api.us-east-1.amazonaws.com/prod';
  
  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String sessionCreateEndpoint = '/session/create';
  static const String commandExecuteEndpoint = '/command/execute';
  static const String aiChatEndpoint = '/ai/chat';
  static const String aiAgentEndpoint = '/ai/agent';
  static const String filesListEndpoint = '/files/list';
  static const String filesReadEndpoint = '/files/read';
  static const String filesWriteEndpoint = '/files/write';
  
  // Configuration flags
  static const bool useAWS = true;
  static const bool mockMode = false;
  static const String environment = 'production';
  
  // Session configuration
  static const Duration sessionTimeout = Duration(hours: 2);
  static const Duration commandTimeout = Duration(minutes: 5);
  static const Duration aiTimeout = Duration(minutes: 1);
  
  // Get full URL for endpoint
  static String getEndpointUrl(String endpoint) {
    return apiBaseUrl + endpoint;
  }
  
  // Get WebSocket URL for endpoint
  static String getWebSocketUrl(String endpoint) {
    return wsBaseUrl + endpoint;
  }
  
  // Headers for API requests
  static Map<String, String> getHeaders({String? sessionId, String? userId}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (sessionId != null) {
      headers['X-Session-ID'] = sessionId;
    }
    
    if (userId != null) {
      headers['X-User-ID'] = userId;
    }
    
    return headers;
  }
}

/// Development/Local Configuration (fallback)
class LocalConfig {
  static const String apiBaseUrl = 'http://localhost:3001';
  static const String wsBaseUrl = 'ws://localhost:3001';
}