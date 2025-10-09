import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';

class WorkstationService {
  static const String baseUrl = AWSConfig.apiBaseUrl;

  /// Crea e avvia una workstation per un repository
  static Future<WorkstationInfo> createWorkstation({
    required String userId,
    required String repoName,
    String? repoUrl,
  }) async {
    print('📡 Chiamata API: POST /workstation/create');
    print('   userId: $userId');
    print('   repoName: $repoName');
    if (repoUrl != null) print('   repoUrl: $repoUrl');
    
    final response = await http.post(
      Uri.parse('$baseUrl/workstation/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'repoName': repoName,
        if (repoUrl != null) 'repoUrl': repoUrl,
      }),
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Workstation creato con successo');
      return WorkstationInfo(
        name: data['workstationName'],
        url: data['url'],
      );
    } else {
      print('❌ Errore creazione: ${response.body}');
      throw Exception('Failed to create workstation: ${response.body}');
    }
  }

  /// Esegue un comando nella workstation
  static Future<String> executeCommand({
    required String workstationName,
    required String command,
  }) async {
    print('⚡ Esecuzione comando nel workstation');
    print('   workstation: $workstationName');
    print('   comando: $command');
    
    final response = await http.post(
      Uri.parse('$baseUrl/workstation/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'workstationName': workstationName,
        'command': command,
      }),
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final output = data['output'] ?? '';
      print('✅ Comando eseguito');
      if (output.isNotEmpty) print('📄 Output: ${output.substring(0, output.length > 100 ? 100 : output.length)}...');
      return output;
    } else {
      print('❌ Errore esecuzione: ${response.body}');
      throw Exception('Failed to execute command: ${response.body}');
    }
  }

  /// Ferma una workstation
  static Future<void> stopWorkstation(String workstationName) async {
    await http.post(
      Uri.parse('$baseUrl/workstation/stop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'workstationName': workstationName}),
    );
  }
}

class WorkstationInfo {
  final String name;
  final String url;

  WorkstationInfo({required this.name, required this.url});
}
