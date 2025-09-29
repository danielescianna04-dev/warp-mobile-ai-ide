/// AWS Configuration for Production Deployment
class AWSConfig {
  // AWS ECS Load Balancer Configuration - UPDATED FOR ECS FARGATE BACKEND
  static const String apiBaseUrl = 'http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com';
  static const String wsBaseUrl = 'ws://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com';
  
  // API Endpoints (mapped to ECS server endpoints)
  static const String healthEndpoint = '/health';
  static const String sessionCreateEndpoint = '/health'; // No session needed for ECS, use health as placeholder
  static const String commandExecuteEndpoint = '/execute-heavy'; // Updated to match ECS server endpoint
  static const String aiChatEndpoint = '/ai/chat'; // Not implemented yet in ECS
  static const String aiAgentEndpoint = '/ai/agent'; // Not implemented yet in ECS
  static const String filesListEndpoint = '/files/list'; // Not implemented yet in ECS
  static const String filesReadEndpoint = '/files/read'; // Not implemented yet in ECS
  static const String filesWriteEndpoint = '/files/write'; // Not implemented yet in ECS
  
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