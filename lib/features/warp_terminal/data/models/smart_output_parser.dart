import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

/// Tipi di output strutturato riconosciuti
enum SmartOutputType {
  flutterStart,      // Avvio app Flutter
  flutterBuild,      // Build in corso
  flutterSuccess,    // Build completato
  urlAvailable,      // URL disponibile
  serverRunning,     // Server in esecuzione
  error,             // Errore
  warning,           // Warning
  success,           // Operazione riuscita
  info,              // Info generica
  progress,          // Operazione in corso
  unknown,           // Output non riconosciuto
}

/// Rappresenta un output intelligente parsato
class SmartOutput {
  final SmartOutputType type;
  final String title;
  final String? subtitle;
  final String? detail;
  final String? url;
  final IconData icon;
  final List<Color> gradientColors;
  final String? rawOutput;
  
  SmartOutput({
    required this.type,
    required this.title,
    this.subtitle,
    this.detail,
    this.url,
    required this.icon,
    required this.gradientColors,
    this.rawOutput,
  });
}

/// Parser intelligente per output terminale
class SmartOutputParser {
  /// Parse l'output grezzo e lo trasforma in SmartOutput
  static SmartOutput parse(String output) {
    // Flutter Web App Start
    if (output.contains('Flutter web app started successfully') || 
        output.contains('flutter run') && output.contains('web')) {
      return _parseFlutterWebStart(output);
    }
    
    // Flutter Build/Compile
    if (output.contains('Running') && output.contains('build') ||
        output.contains('Compiling') ||
        output.contains('Building')) {
      return _parseFlutterBuild(output);
    }
    
    // URL Available
    if (output.contains('http://') || output.contains('https://')) {
      return _parseUrlAvailable(output);
    }
    
    // Docker/Server start
    if (output.contains('Server started') || 
        output.contains('Listening on') ||
        output.contains('Running on')) {
      return _parseServerStart(output);
    }
    
    // Success messages
    if (output.contains('✓') || output.contains('✅') || 
        output.contains('Successfully') || output.contains('succeeded')) {
      return _parseSuccess(output);
    }
    
    // Error messages
    if (output.contains('Error') || output.contains('error:') || 
        output.contains('✗') || output.contains('❌') ||
        output.contains('failed')) {
      return _parseError(output);
    }
    
    // Warning messages
    if (output.contains('Warning') || output.contains('⚠')) {
      return _parseWarning(output);
    }
    
    // Progress/Loading
    if (output.contains('...') || output.contains('Loading') ||
        output.contains('Fetching') || output.contains('Downloading')) {
      return _parseProgress(output);
    }
    
    // Default: info generica
    return SmartOutput(
      type: SmartOutputType.info,
      title: _extractFirstLine(output),
      detail: output.length > 100 ? null : output,
      icon: Icons.info_outline,
      gradientColors: [
        AppColors.textSecondary.withValues(alpha: 0.3),
        AppColors.textSecondary.withValues(alpha: 0.1),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseFlutterWebStart(String output) {
    final urlMatch = RegExp(r'https?://[^\\s]+').firstMatch(output);
    final url = urlMatch?.group(0);
    
    return SmartOutput(
      type: SmartOutputType.flutterStart,
      title: 'App Flutter avviata',
      subtitle: 'Applicazione web in esecuzione',
      url: url,
      icon: Icons.check_circle_outline,
      gradientColors: [
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseFlutterBuild(String output) {
    return SmartOutput(
      type: SmartOutputType.flutterBuild,
      title: 'Compilazione in corso',
      subtitle: 'Build in esecuzione...',
      detail: _extractRelevantDetails(output),
      icon: Icons.build_outlined,
      gradientColors: [
        AppColors.primary.withValues(alpha: 0.8),
        AppColors.primary.withValues(alpha: 0.6),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseUrlAvailable(String output) {
    final urlMatch = RegExp(r'https?://[^\\s]+').firstMatch(output);
    final url = urlMatch?.group(0);
    
    String title = 'URL disponibile';
    String? subtitle;
    
    if (output.contains('AWS') || output.contains('ECS')) {
      subtitle = 'AWS ECS Fargate';
    } else if (output.contains('localhost')) {
      subtitle = 'Ambiente locale';
    } else {
      subtitle = 'Web app accessibile';
    }
    
    return SmartOutput(
      type: SmartOutputType.urlAvailable,
      title: title,
      subtitle: subtitle,
      url: url,
      icon: Icons.link_rounded,
      gradientColors: [
        const Color(0xFF06B6D4),
        const Color(0xFF0891B2),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseServerStart(String output) {
    final portMatch = RegExp(r':(\\d+)').firstMatch(output);
    final port = portMatch?.group(1);
    
    return SmartOutput(
      type: SmartOutputType.serverRunning,
      title: 'Server avviato',
      subtitle: port != null ? 'Porta $port' : 'In esecuzione',
      detail: _extractRelevantDetails(output),
      icon: Icons.circle_outlined,
      gradientColors: [
        const Color(0xFF8B5CF6),
        const Color(0xFF7C3AED),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseSuccess(String output) {
    return SmartOutput(
      type: SmartOutputType.success,
      title: 'Operazione completata',
      subtitle: _extractFirstLine(output).replaceAll('✓', '').replaceAll('✅', '').trim(),
      icon: Icons.check_circle_outline,
      gradientColors: [
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseError(String output) {
    final errorLine = output.split('\\n').firstWhere(
      (line) => line.toLowerCase().contains('error'),
      orElse: () => output.split('\\n').first,
    );
    
    return SmartOutput(
      type: SmartOutputType.error,
      title: 'Errore',
      subtitle: errorLine.replaceAll('Error:', '').replaceAll('error:', '').trim(),
      detail: output.length < 200 ? output : null,
      icon: Icons.error_outline,
      gradientColors: [
        const Color(0xFFEF4444),
        const Color(0xFFDC2626),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseWarning(String output) {
    return SmartOutput(
      type: SmartOutputType.warning,
      title: 'Attenzione',
      subtitle: _extractFirstLine(output).replaceAll('Warning:', '').replaceAll('⚠', '').trim(),
      icon: Icons.warning_amber_outlined,
      gradientColors: [
        const Color(0xFFF59E0B),
        const Color(0xFFD97706),
      ],
      rawOutput: output,
    );
  }
  
  static SmartOutput _parseProgress(String output) {
    return SmartOutput(
      type: SmartOutputType.progress,
      title: 'In corso',
      subtitle: _extractFirstLine(output).replaceAll('...', '').trim(),
      icon: Icons.more_horiz,
      gradientColors: [
        AppColors.primary.withValues(alpha: 0.6),
        AppColors.primary.withValues(alpha: 0.4),
      ],
      rawOutput: output,
    );
  }
  
  static String _extractFirstLine(String text) {
    final lines = text.trim().split('\n');
    return lines.first.trim();
  }
  
  static String? _extractRelevantDetails(String text) {
    final lines = text.trim().split('\n');
    if (lines.length <= 1) return null;
    
    // Prendi le prime 3 righe significative (non vuote)
    final relevantLines = lines
        .where((line) => line.trim().isNotEmpty)
        .take(3)
        .join('\n');
    
    return relevantLines.length > 150 
        ? '${relevantLines.substring(0, 150)}...' 
        : relevantLines;
  }
}
