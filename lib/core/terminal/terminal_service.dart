import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';

// Terminal output stream controller for real-time updates
StreamController<CommandResult> terminalOutputStreamController = StreamController<CommandResult>.broadcast();

class TerminalService {
  static final TerminalService _instance = TerminalService._internal();
  factory TerminalService() => _instance;
  TerminalService._internal();

  // Configuration
  bool _useRemoteTerminal = true; // Now default to true for AWS backend
  String _backendUrl = AWSConfig.useAWS ? AWSConfig.apiBaseUrl : 'ws://localhost:3001';
  String _userId = 'flutter-user-${const Uuid().v4()}';
  
  // Local terminal state (fallback)
  String _currentDirectory = Directory.current.path;
  Map<String, String> _environment = Map.from(Platform.environment);
  
  // WebSocket connection
  WebSocketChannel? _channel;
  StreamController<CommandResult>? _outputController;
  bool _isConnected = false;
  String? _sessionId;
  Timer? _pingTimer;
  
  // Connection state
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  
  // Exposed ports from container
  Map<String, String> _exposedPorts = {};

  Future<void> initialize({bool useRemoteTerminal = true}) async {
    _useRemoteTerminal = useRemoteTerminal;
    
    if (_useRemoteTerminal && AWSConfig.useAWS) {
      await _initializeAWSSession();
    } else if (_useRemoteTerminal) {
      await _connectToBackend();
    } else {
      print('📱 Local terminal initialized');
    }
  }
  
  // AWS Session Management
  Future<void> _initializeAWSSession() async {
    try {
      print('🌐 Initializing AWS session for user: $_userId');
      
      final response = await http.post(
        Uri.parse(AWSConfig.getEndpointUrl(AWSConfig.sessionCreateEndpoint)),
        headers: AWSConfig.getHeaders(userId: _userId),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _sessionId = data['session']['sessionId'];
          _isConnected = true;
          print('✅ AWS session initialized: $_sessionId');
          print('💾 Workspace: ${data['session']['workspaceDir']}');
        } else {
          throw Exception('Session creation failed: ${data['error']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ AWS session initialization failed: $e');
      _useRemoteTerminal = false;
    }
  }
  
  Future<void> _connectToBackend() async {
    if (_isConnected || _isReconnecting) return;
    
    try {
      _isReconnecting = true;
      print('Connecting to backend: $_backendUrl (attempt ${_reconnectAttempts + 1})');
      
      _channel = WebSocketChannel.connect(Uri.parse(_backendUrl));
      
      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data);
            _handleBackendMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );
      
      // Initialize session
      _channel!.sink.add(json.encode({
        'type': 'init',
        'userId': 'flutter-user-${DateTime.now().millisecondsSinceEpoch}'
      }));
      
      _reconnectAttempts = 0;
      _isReconnecting = false;
      
    } catch (e) {
      print('Failed to connect to backend: $e');
      _isReconnecting = false;
      await _handleConnectionError();
    }
  }
  
  void _handleDisconnection() {
    _isConnected = false;
    _pingTimer?.cancel();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('Max reconnection attempts reached. Falling back to local mode.');
      _useRemoteTerminal = false;
    }
  }
  
  void _scheduleReconnect() {
    final delay = Duration(seconds: math.min(5 * (_reconnectAttempts + 1), 30));
    print('Scheduling reconnection in ${delay.inSeconds} seconds...');
    
    Timer(delay, () {
      _reconnectAttempts++;
      _connectToBackend();
    });
  }
  
  Future<void> _handleConnectionError() async {
    _reconnectAttempts++;
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('Switching to local terminal mode due to connection failure.');
      _useRemoteTerminal = false;
    }
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode({'type': 'ping'}));
      }
    });
  }
  
  void _handleBackendMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'init_result':
        if (data['success'] == true) {
          _isConnected = true;
          _sessionId = data['sessionId'];
          _exposedPorts = Map<String, String>.from(data['exposedPorts'] ?? {});
          _startPingTimer();
          print('✅ Session ready: $_sessionId');
          print('🔌 Exposed ports: $_exposedPorts');
        } else {
          print('❌ Session initialization failed: ${data['error']}');
        }
        break;
        
      case 'command_result':
        final result = CommandResult(
          output: data['output'] ?? '',
          isSuccess: data['success'] ?? false,
          isClearCommand: data['clearTerminal'] ?? false,
        );
        
        // Update exposed ports if provided
        if (data['exposedPorts'] != null) {
          _exposedPorts = Map<String, String>.from(data['exposedPorts']);
        }
        
        // Check if web server was detected
        if (data['webServerDetected'] == true) {
          print('🚀 Web server detected! Ports: $_exposedPorts');
        }
        
        terminalOutputStreamController.add(result);
        break;
        
      case 'command_output':
        // Real-time output from command execution
        final result = CommandResult(
          output: data['output'] ?? '',
          isSuccess: true,
          isClearCommand: false,
        );
        terminalOutputStreamController.add(result);
        break;
        
      case 'pong':
        // Keep-alive response
        break;
        
      case 'error':
        print('🚨 Backend error: ${data['message']}');
        break;

      // AI Agent messages
      case 'ai_chat_response':
        _handleAIChatResponse(data['response']);
        break;
        
      case 'ai_chat_error':
        print('🚨 AI Chat error: ${data['error']}');
        break;
        
      case 'agent_task_started':
        print('🤖 Agent task started: ${data['task']}');
        break;
        
      case 'agent_step_completed':
        print('🔧 Agent step completed: ${data['step']['action']}');
        break;
        
      case 'agent_task_completed':
        print('🎉 Agent task completed: ${data['status']}');
        break;
        
      case 'agent_task_error':
        print('🚨 Agent task error: ${data['error']}');
        break;
        
      case 'agent_providers':
        print('🤖 Available AI providers: ${data['providers']}');
        break;
        
      case 'agent_provider_switched':
        print('🔄 AI provider switched to: ${data['provider']}');
        break;
        
      case 'server_detected':
        print('🌐 Server detected: ${data['serverType']} on port ${data['port']}');
        // Update exposed ports
        if (data['hostPort'] != null && data['port'] != null) {
          _exposedPorts['${data['port']}/tcp'] = 'http://localhost:${data['hostPort']}';
        }
        break;
        
      default:
        print('❓ Unknown message type: ${data['type']}');
    }
  }

  Future<CommandResult> executeCommand(String command) async {
    if (_useRemoteTerminal && _isConnected) {
      // For AWS, we use HTTP instead of WebSocket
      if (AWSConfig.useAWS) {
        return await _executeAWSCommand(command);
      }
      // For local development, we use WebSocket
      else if (_channel != null) {
        return _executeRemoteCommand(command);
      }
    }
    
    // Fallback to local execution
    return _executeLocalCommand(command);
  }
  
  Future<CommandResult> _executeRemoteCommand(String command) async {
    try {
      // Use WebSocket for local development
      if (_channel == null || !_isConnected) {
        throw Exception('WebSocket connection not available');
      }
      
      // Send command to backend
      _channel!.sink.add(json.encode({
        'type': 'command',
        'command': command,
        'sessionId': _sessionId,
      }));
      
      // For remote commands, we return immediately
      // The actual result will come through the WebSocket stream
      return CommandResult(
        output: 'Executing: $command',
        isSuccess: true,
        isClearCommand: command.trim() == 'clear',
      );
    } catch (e) {
      return CommandResult(
        output: 'Remote terminal error: $e',
        isSuccess: false,
        isClearCommand: false,
      );
    }
  }

  Future<CommandResult> _executeAWSCommand(String command) async {
    try {
      if (_sessionId == null) {
        throw Exception('No AWS session available');
      }

      final url = AWSConfig.getEndpointUrl(AWSConfig.commandExecuteEndpoint);
      final headers = AWSConfig.getHeaders(
        sessionId: _sessionId,
        userId: _userId,
      );

      final requestBody = <String, dynamic>{
        'command': command,
        'sessionId': _sessionId,
      };

      print('🚀 Executing AWS command: $command');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        AWSConfig.commandTimeout,
        onTimeout: () {
          throw Exception('Command execution timed out');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle successful command execution
        if (responseData['success'] == true) {
          final result = CommandResult(
            output: responseData['output'] ?? '',
            isSuccess: true,
            isClearCommand: command.trim() == 'clear',
          );

          // Update exposed ports if provided
          if (responseData['exposedPorts'] != null) {
            _exposedPorts = Map<String, String>.from(responseData['exposedPorts']);
          }

          // Check if web server was detected
          if (responseData['webServerDetected'] == true) {
            print('🚀 Web server detected! Ports: $_exposedPorts');
          }

          return result;
        } else {
          return CommandResult(
            output: responseData['error'] ?? 'Command execution failed',
            isSuccess: false,
            isClearCommand: false,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return CommandResult(
          output: 'AWS API Error (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}',
          isSuccess: false,
          isClearCommand: false,
        );
      }
    } catch (e) {
      print('❌ AWS command execution error: $e');
      return CommandResult(
        output: 'AWS command execution error: $e',
        isSuccess: false,
        isClearCommand: false,
      );
    }
  }

  Future<void> _sendAWSAIChat(String prompt, {String? model, double? temperature}) async {
    try {
      if (_sessionId == null) {
        print('⚠️ Cannot send AI chat: no AWS session available');
        return;
      }

      final url = AWSConfig.getEndpointUrl(AWSConfig.aiChatEndpoint);
      final headers = AWSConfig.getHeaders(
        sessionId: _sessionId,
        userId: _userId,
      );

      final requestBody = <String, dynamic>{
        'prompt': prompt,
        'sessionId': _sessionId,
      };

      if (model != null) requestBody['model'] = model;
      if (temperature != null) requestBody['temperature'] = temperature;

      print('🤖 Sending AI chat request');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        AWSConfig.aiTimeout,
        onTimeout: () {
          throw Exception('AI chat request timed out');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          _handleAIChatResponse(responseData['response']);
        } else {
          print('❌ AI chat error: ${responseData['error']}');
          final result = CommandResult(
            output: '🤖 AI Chat Error: ${responseData['error']}',
            isSuccess: false,
            isClearCommand: false,
          );
          terminalOutputStreamController.add(result);
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ AI chat API error: ${errorData['error']}');
        final result = CommandResult(
          output: '🤖 AI Chat API Error (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}',
          isSuccess: false,
          isClearCommand: false,
        );
        terminalOutputStreamController.add(result);
      }
    } catch (e) {
      print('❌ AWS AI chat error: $e');
      final result = CommandResult(
        output: '🤖 AI Chat Error: $e',
        isSuccess: false,
        isClearCommand: false,
      );
      terminalOutputStreamController.add(result);
    }
  }

  Future<void> _executeAWSAgentTask(String task) async {
    try {
      if (_sessionId == null) {
        print('⚠️ Cannot execute agent task: no AWS session available');
        return;
      }

      final url = AWSConfig.getEndpointUrl(AWSConfig.aiAgentEndpoint);
      final headers = AWSConfig.getHeaders(
        sessionId: _sessionId,
        userId: _userId,
      );

      final requestBody = <String, dynamic>{
        'task': task,
        'sessionId': _sessionId,
      };

      print('🤖 Requesting autonomous task: $task');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        AWSConfig.aiTimeout,
        onTimeout: () {
          throw Exception('Agent task request timed out');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final result = CommandResult(
            output: '🤖 Agent Task Started: $task\nStatus: ${responseData['status']}',
            isSuccess: true,
            isClearCommand: false,
          );
          terminalOutputStreamController.add(result);
        } else {
          print('❌ Agent task error: ${responseData['error']}');
          final result = CommandResult(
            output: '🤖 Agent Task Error: ${responseData['error']}',
            isSuccess: false,
            isClearCommand: false,
          );
          terminalOutputStreamController.add(result);
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ Agent task API error: ${errorData['error']}');
        final result = CommandResult(
          output: '🤖 Agent Task API Error (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}',
          isSuccess: false,
          isClearCommand: false,
        );
        terminalOutputStreamController.add(result);
      }
    } catch (e) {
      print('❌ AWS agent task error: $e');
      final result = CommandResult(
        output: '🤖 Agent Task Error: $e',
        isSuccess: false,
        isClearCommand: false,
      );
      terminalOutputStreamController.add(result);
    }
  }
  
  Future<CommandResult> _executeLocalCommand(String command) async {
    try {
      // Parse command and arguments
      List<String> parts = _parseCommand(command);
      if (parts.isEmpty) {
        return CommandResult(
          output: '',
          isSuccess: true,
          isClearCommand: false,
        );
      }

      String executable = parts[0];
      List<String> arguments = parts.length > 1 ? parts.sublist(1) : [];

      // Handle special commands
      if (executable == 'cd') {
        return _handleChangeDirectory(arguments);
      }

      if (executable == 'pwd') {
        return CommandResult(
          output: currentDirectory,
          isSuccess: true,
          isClearCommand: false,
        );
      }

      if (executable == 'clear') {
        return CommandResult(
          output: '',
          isSuccess: true,
          isClearCommand: true,
        );
      }

      if (executable == 'ls' || executable == 'dir') {
        return _handleListDirectory(arguments);
      }

      // Execute regular command
      ProcessResult result = await Process.run(
        executable,
        arguments,
        workingDirectory: currentDirectory,
        environment: _environment,
        runInShell: true,
      );

      String output = '';
      if (result.stdout.toString().isNotEmpty) {
        output += result.stdout.toString();
      }
      if (result.stderr.toString().isNotEmpty) {
        if (output.isNotEmpty) output += '\n';
        output += result.stderr.toString();
      }

      return CommandResult(
        output: output,
        isSuccess: result.exitCode == 0,
        isClearCommand: false,
      );
    } catch (e) {
      return CommandResult(
        output: 'Error: $e',
        isSuccess: false,
        isClearCommand: false,
      );
    }
  }

  List<String> _parseCommand(String command) {
    // Simple command parsing - can be enhanced for complex cases
    return command.trim().split(RegExp(r'\s+'));
  }

  CommandResult _handleChangeDirectory(List<String> arguments) {
    try {
      String targetPath;
      
      if (arguments.isEmpty) {
        // cd without arguments goes to home
        targetPath = _environment['HOME'] ?? Directory.current.path;
      } else {
        targetPath = arguments[0];
      }

      // Handle relative paths
      if (!path.isAbsolute(targetPath)) {
        targetPath = path.join(currentDirectory, targetPath);
      }

      // Resolve path (handles .. and . properly)
      targetPath = path.canonicalize(targetPath);

      Directory targetDir = Directory(targetPath);
      if (targetDir.existsSync()) {
        _currentDirectory = targetPath;
        return CommandResult(
          output: '',
          isSuccess: true,
          isClearCommand: false,
        );
      } else {
        return CommandResult(
          output: 'cd: no such file or directory: $targetPath',
          isSuccess: false,
          isClearCommand: false,
        );
      }
    } catch (e) {
      return CommandResult(
        output: 'cd: $e',
        isSuccess: false,
        isClearCommand: false,
      );
    }
  }

  CommandResult _handleListDirectory(List<String> arguments) {
    try {
      String targetPath = arguments.isNotEmpty ? arguments[0] : currentDirectory;
      
      if (!path.isAbsolute(targetPath)) {
        targetPath = path.join(currentDirectory, targetPath);
      }

      Directory dir = Directory(targetPath);
      if (!dir.existsSync()) {
        return CommandResult(
          output: 'ls: cannot access \'$targetPath\': No such file or directory',
          isSuccess: false,
          isClearCommand: false,
        );
      }

      List<FileSystemEntity> entities = dir.listSync();
      entities.sort((a, b) => a.path.compareTo(b.path));

      List<String> entries = [];
      for (var entity in entities) {
        String name = path.basename(entity.path);
        if (entity is Directory) {
          entries.add('$name/');
        } else {
          entries.add(name);
        }
      }

      return CommandResult(
        output: entries.join('\n'),
        isSuccess: true,
        isClearCommand: false,
      );
    } catch (e) {
      return CommandResult(
        output: 'ls: $e',
        isSuccess: false,
        isClearCommand: false,
      );
    }
  }

  String getPrompt() {
    if (_useRemoteTerminal && _isConnected) {
      return 'warp-container \$ ';
    }
    
    String shortPath = currentDirectory;
    String home = _environment['HOME'] ?? '';
    
    if (home.isNotEmpty && currentDirectory.startsWith(home)) {
      shortPath = currentDirectory.replaceFirst(home, '~');
    }
    
    // Get last 2 path components to keep prompt short
    List<String> pathParts = shortPath.split('/');
    if (pathParts.length > 2) {
      shortPath = '.../${pathParts[pathParts.length - 2]}/${pathParts.last}';
    }
    
    return '$shortPath \$ ';
  }
  
  // Exposed ports access
  Map<String, String> get exposedPorts => Map.from(_exposedPorts);
  
  bool get hasWebServerRunning => _exposedPorts.isNotEmpty;
  
  String? getWebServerUrl() {
    // Return the first available port URL
    for (String url in _exposedPorts.values) {
      if (url.isNotEmpty) return url;
    }
    return null;
  }
  
  bool get isRemoteMode => _useRemoteTerminal;
  bool get isConnected => _isConnected;
  
  String get currentDirectory => _useRemoteTerminal && _isConnected 
      ? '/workspace' // Default for Docker containers
      : _currentDirectory;
      
  // AI Agent methods
  Future<void> sendAIChat(String prompt, {String? model, double? temperature}) async {
    if (AWSConfig.useAWS) {
      await _sendAWSAIChat(prompt, model: model, temperature: temperature);
      return;
    }
    
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot send AI chat: not connected to backend');
      return;
    }
    
    _channel!.sink.add(json.encode({
      'type': 'ai_chat',
      'prompt': prompt,
      'model': model,
      'temperature': temperature,
    }));
  }
  
  Future<void> executeAgentTask(String task) async {
    if (AWSConfig.useAWS) {
      await _executeAWSAgentTask(task);
      return;
    }
    
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot execute agent task: not connected to backend');
      return;
    }
    
    print('🤖 Requesting autonomous task: $task');
    _channel!.sink.add(json.encode({
      'type': 'agent_execute_task',
      'task': task,
    }));
  }
  
  Future<void> getAIProviders() async {
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot get AI providers: not connected to backend');
      return;
    }
    
    _channel!.sink.add(json.encode({
      'type': 'agent_get_providers',
    }));
  }
  
  Future<void> switchAIProvider(String provider) async {
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot switch AI provider: not connected to backend');
      return;
    }
    
    _channel!.sink.add(json.encode({
      'type': 'agent_switch_provider',
      'provider': provider,
    }));
  }
  
  void _handleAIChatResponse(Map<String, dynamic> response) {
    // Create a terminal item for AI response
    final result = CommandResult(
      output: '🤖 AI: ${response['content']}\n\nProvider: ${response['provider']} | Model: ${response['model']} | Tokens: ${response['tokensUsed']}',
      isSuccess: true,
      isClearCommand: false,
    );
    terminalOutputStreamController.add(result);
  }
  
  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _outputController?.close();
  }
}

// Command execution result for new architecture
class CommandResult {
  final String output;
  final bool isSuccess;
  final bool isClearCommand;

  CommandResult({
    required this.output,
    required this.isSuccess,
    this.isClearCommand = false,
  });
}


