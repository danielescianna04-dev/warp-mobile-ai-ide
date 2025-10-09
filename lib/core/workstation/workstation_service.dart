import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';

class WorkstationService {
  static const String baseUrl = AWSConfig.apiBaseUrl;

  /// Crea e avvia una workstation per un repository
  static Future<WorkstationInfo> createWorkstation({
    required String userId,
    required String repoName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workstation/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'repoName': repoName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WorkstationInfo(
        name: data['workstationName'],
        url: data['url'],
      );
    } else {
      throw Exception('Failed to create workstation: ${response.body}');
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
