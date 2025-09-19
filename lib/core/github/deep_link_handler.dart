import 'dart:async';
import 'package:flutter/services.dart';
import 'github_service.dart';

/// Handles deep link navigation for OAuth callbacks
class DeepLinkHandler {
  static const MethodChannel _channel = MethodChannel('warp_mobile/deep_link');
  static StreamController<Uri>? _linkStreamController;
  
  /// Stream of incoming deep links
  static Stream<Uri> get linkStream {
    _linkStreamController ??= StreamController<Uri>.broadcast();
    return _linkStreamController!.stream;
  }
  
  /// Initialize deep link handling
  static Future<void> initialize() async {
    try {
      // Set up method channel listener for deep links
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Check for initial deep link (when app was launched via deep link)
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        final uri = Uri.parse(initialLink);
        _linkStreamController?.add(uri);
      }
      
      print('🔗 Deep link handler initialized');
    } catch (e) {
      print('❌ Failed to initialize deep link handler: $e');
    }
  }
  
  /// Handle incoming method calls from native platform
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final String link = call.arguments as String;
        final uri = Uri.parse(link);
        _linkStreamController?.add(uri);
        return null;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }
  
  /// Handle GitHub OAuth callback from deep link
  static Future<bool> handleGitHubCallback(Uri uri) async {
    try {
      if (uri.scheme == 'warp-mobile' && uri.host == 'oauth' && uri.pathSegments.contains('github')) {
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final error = uri.queryParameters['error'];
        
        if (error != null) {
          print('❌ GitHub OAuth error: $error');
          final errorDescription = uri.queryParameters['error_description'];
          if (errorDescription != null) {
            print('❌ Error description: $errorDescription');
          }
          return false;
        }
        
        if (code != null) {
          print('✅ Received GitHub OAuth callback with code');
          final gitHubService = GitHubService();
          return await gitHubService.handleAuthCallback(code, state);
        } else {
          print('❌ No authorization code in GitHub callback');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error handling GitHub callback: $e');
      return false;
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _linkStreamController?.close();
    _linkStreamController = null;
  }
}