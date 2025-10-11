import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';

class WorkstationService {
  static const String baseUrl = AWSConfig.apiBaseUrl;

  /// Inizializza workspace per un utente (istantaneo se già esiste)
  static Future<WorkstationInfo> initWorkspace({
    required String userId,
    String? repoUrl,
    String? repoName,
  }) async {
    print('📡 Chiamata API: POST /workspace/init');
    print('   userId: $userId');
    if (repoUrl != null) print('   repoUrl: $repoUrl');
    if (repoName != null) print('   repoName: $repoName');
    
    final response = await http.post(
      Uri.parse('$baseUrl/workspace/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        if (repoUrl != null) 'repoUrl': repoUrl,
        if (repoName != null) 'repoName': repoName,
      }),
    ).timeout(
      const Duration(minutes: 15), // Increased for large repos (up to 5GB)
      onTimeout: () {
        throw TimeoutException('Workspace init timeout - repository might be too large');
      },
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Workspace pronto: ${data['message']}');
      return WorkstationInfo(
        name: data['workspaceName'],
        url: '',
      );
    } else {
      print('❌ Errore init: ${response.body}');
      throw Exception('Failed to init workspace: ${response.body}');
    }
  }

  /// Analizza il workspace per file mancanti
  static Future<AnalysisResult> analyzeWorkspace({
    required String userId,
    required String repoName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/workspace/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'repoName': repoName,
        }),
      ).timeout(const Duration(minutes: 2));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return AnalysisResult(
          success: true,
          missingFiles: (data['missingFiles'] as List?)
              ?.map((f) => MissingFile.fromJson(f))
              .toList() ?? [],
          message: data['message'] ?? '',
        );
      } else {
        return AnalysisResult(
          success: false,
          missingFiles: [],
          message: data['error'] ?? 'Analysis failed',
        );
      }
    } catch (e) {
      return AnalysisResult(
        success: false,
        missingFiles: [],
        message: e.toString(),
      );
    }
  }

  /// Esegue un comando nel workspace (istantaneo)
  static Future<CommandResult> executeCommand({
    required String userId,
    required String command,
    String? repoName,
  }) async {
    print('⚡ Esecuzione comando nel workspace');
    print('   userId: $userId');
    print('   comando: $command');
    if (repoName != null) print('   repoName: $repoName');
    
    final response = await http.post(
      Uri.parse('$baseUrl/workspace/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'command': command,
        if (repoName != null) 'repoName': repoName,
      }),
    ).timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        throw TimeoutException('Command execution timeout');
      },
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Comando eseguito');
      
      final stdout = data['stdout'] ?? '';
      final stderr = data['stderr'] ?? '';
      final exitCode = data['exitCode'] ?? 0;
      final previewUrl = data['previewUrl'];
      final isServerCommand = data['isServerCommand'] ?? false;
      
      print('📄 Output: $stdout');
      if (stderr.isNotEmpty) {
        print('⚠️ Stderr: $stderr');
      }
      print('🔢 Exit code: $exitCode');
      
      if (previewUrl != null) {
        print('🌐 Preview URL: $previewUrl');
      }
      
      return CommandResult(
        stdout: stdout,
        stderr: stderr,
        exitCode: exitCode,
        previewUrl: previewUrl,
        isServerCommand: isServerCommand,
      );
    } else {
      print('❌ Errore esecuzione: ${response.body}');
      throw Exception('Failed to execute command: ${response.body}');
    }
  }

  // Backward compatibility - redirect to new methods
  static Future<WorkstationInfo> createWorkstation({
    required String userId,
    required String repoName,
    String? repoUrl,
  }) async {
    return initWorkspace(userId: userId, repoUrl: repoUrl, repoName: repoName);
  }
}

class WorkstationInfo {
  final String name;
  final String url;

  WorkstationInfo({
    required this.name,
    required this.url,
  });
}

class CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final String? previewUrl;
  final bool isServerCommand;

  CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    this.previewUrl,
    this.isServerCommand = false,
  });
  
  String get output {
    if (exitCode != 0) {
      return 'Error (exit $exitCode):\n$stderr\n$stdout';
    }
    return stdout;
  }
}

class AnalysisResult {
  final bool success;
  final List<MissingFile> missingFiles;
  final String message;

  AnalysisResult({
    required this.success,
    required this.missingFiles,
    required this.message,
  });
}

class MissingFile {
  final String path;
  final String reason;

  MissingFile({
    required this.path,
    required this.reason,
  });

  factory MissingFile.fromJson(Map<String, dynamic> json) {
    return MissingFile(
      path: json['path'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

