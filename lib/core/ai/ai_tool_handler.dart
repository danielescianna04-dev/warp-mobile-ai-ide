import 'dart:convert';
import 'package:http/http.dart' as http;
import '../workstation/workstation_service.dart';

class AIToolHandler {
  static const String _baseUrl = 'https://drape-ai-backend-74904913373.us-central1.run.app';
  
  static Future<String> handleToolCall({
    required String toolName,
    required Map<String, dynamic> parameters,
    required String userId,
    required String repoName,
  }) async {
    try {
      switch (toolName) {
        case 'readFile':
          return await _readFile(
            userId: userId,
            repoName: repoName,
            filePath: parameters['filePath'] as String,
          );
          
        case 'writeFile':
          return await _writeFile(
            userId: userId,
            repoName: repoName,
            filePath: parameters['filePath'] as String,
            content: parameters['content'] as String,
          );
          
        case 'listFiles':
          return await _listFiles(
            userId: userId,
            repoName: repoName,
            directory: parameters['directory'] as String? ?? '.',
          );
          
        case 'executeCommand':
          return await _executeCommand(
            userId: userId,
            repoName: repoName,
            command: parameters['command'] as String,
          );
          
        default:
          return 'Error: Unknown tool "$toolName"';
      }
    } catch (e) {
      return 'Error executing tool: $e';
    }
  }
  
  static Future<String> _readFile({
    required String userId,
    required String repoName,
    required String filePath,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspace/read-file'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'repoName': repoName,
        'filePath': filePath,
      }),
    ).timeout(const Duration(seconds: 30));
    
    final data = json.decode(response.body);
    if (data['success']) {
      return data['content'];
    } else {
      return 'Error: ${data['error']}';
    }
  }
  
  static Future<String> _writeFile({
    required String userId,
    required String repoName,
    required String filePath,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspace/write-file'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'repoName': repoName,
        'filePath': filePath,
        'content': content,
      }),
    ).timeout(const Duration(seconds: 30));
    
    final data = json.decode(response.body);
    if (data['success']) {
      return 'File written successfully: $filePath';
    } else {
      return 'Error: ${data['error']}';
    }
  }
  
  static Future<String> _listFiles({
    required String userId,
    required String repoName,
    required String directory,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspace/list-files'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'repoName': repoName,
        'directory': directory,
      }),
    ).timeout(const Duration(seconds: 30));
    
    final data = json.decode(response.body);
    if (data['success']) {
      final files = (data['files'] as List)
          .map((f) => '${f['isDirectory'] ? '📁' : '📄'} ${f['name']}')
          .join('\n');
      return 'Files in $directory:\n$files';
    } else {
      return 'Error: ${data['error']}';
    }
  }
  
  static Future<String> _executeCommand({
    required String userId,
    required String repoName,
    required String command,
  }) async {
    final result = await WorkstationService.executeCommand(
      userId: userId,
      command: command,
      repoName: repoName,
    );
    
    if (result.exitCode == 0) {
      return result.stdout.isNotEmpty ? result.stdout : 'Command executed successfully';
    } else {
      return 'Error: ${result.stderr}';
    }
  }
  
  static List<Map<String, dynamic>> getToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'readFile',
          'description': 'Read the content of a file in the workspace',
          'parameters': {
            'type': 'object',
            'properties': {
              'filePath': {
                'type': 'string',
                'description': 'Path to the file relative to repository root (e.g., "lib/main.dart")'
              }
            },
            'required': ['filePath']
          }
        }
      },
      {
        'type': 'function',
        'function': {
          'name': 'writeFile',
          'description': 'Create or modify a file in the workspace',
          'parameters': {
            'type': 'object',
            'properties': {
              'filePath': {
                'type': 'string',
                'description': 'Path to the file relative to repository root'
              },
              'content': {
                'type': 'string',
                'description': 'Content to write to the file'
              }
            },
            'required': ['filePath', 'content']
          }
        }
      },
      {
        'type': 'function',
        'function': {
          'name': 'listFiles',
          'description': 'List files and directories in a directory',
          'parameters': {
            'type': 'object',
            'properties': {
              'directory': {
                'type': 'string',
                'description': 'Directory path relative to repository root (default: ".")'
              }
            }
          }
        }
      },
      {
        'type': 'function',
        'function': {
          'name': 'executeCommand',
          'description': 'Execute a terminal command in the workspace',
          'parameters': {
            'type': 'object',
            'properties': {
              'command': {
                'type': 'string',
                'description': 'Command to execute (e.g., "flutter pub get", "git status")'
              }
            },
            'required': ['command']
          }
        }
      }
    ];
  }
}
