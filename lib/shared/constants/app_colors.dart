import 'package:flutter/material.dart';

/// Application color scheme inspired by Warp terminal
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryDark = Color(0xFF00A080);
  static const Color primaryLight = Color(0xFF33E0BB);

  // Background colors
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF21262D);

  // Text colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // Editor colors
  static const Color editorBackground = Color(0xFF0D1117);
  static const Color editorLineNumbers = Color(0xFF6E7681);
  static const Color editorSelection = Color(0xFF264F78);
  static const Color editorCurrentLine = Color(0xFF2A2E3A);

  // Terminal colors
  static const Color terminalBackground = Color(0xFF0D1117);
  static const Color terminalText = Color(0xFFE6EDF3);
  static const Color terminalGreen = Color(0xFF7CE38B);
  static const Color terminalYellow = Color(0xFFE3B341);
  static const Color terminalRed = Color(0xFFFF6B6B);
  static const Color terminalBlue = Color(0xFF409CFF);
  static const Color terminalMagenta = Color(0xFFFF7CE0);
  static const Color terminalCyan = Color(0xFF00D4AA);

  // Status colors
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF0969DA);

  // AI-specific colors
  static const Color aiAccent = Color(0xFF8B5CF6);
  static const Color aiSecondary = Color(0xFFEC4899);
  static const Color aiGradientStart = Color(0xFF8B5CF6);
  static const Color aiGradientEnd = Color(0xFFEC4899);

  // Syntax highlighting colors
  static const Color syntaxKeyword = Color(0xFFFF7B72);
  static const Color syntaxString = Color(0xFFA5D6FF);
  static const Color syntaxComment = Color(0xFF8B949E);
  static const Color syntaxNumber = Color(0xFF79C0FF);
  static const Color syntaxFunction = Color(0xFFD2A8FF);
  static const Color syntaxClass = Color(0xFFFFA657);
  static const Color syntaxVariable = Color(0xFFFFA657);

  // Utility colors
  static const Color divider = Color(0xFF30363D);
  static const Color border = Color(0xFF30363D);
  static const Color shadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient aiGradient = LinearGradient(
    colors: [aiGradientStart, aiGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Material color swatch for theme integration
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF00D4AA,
    <int, Color>{
      50: Color(0xFFE0FFF9),
      100: Color(0xFFB3FFF0),
      200: Color(0xFF80FFE6),
      300: Color(0xFF4DFFDB),
      400: Color(0xFF26FFD3),
      500: Color(0xFF00D4AA),
      600: Color(0xFF00C29A),
      700: Color(0xFF00A080),
      800: Color(0xFF008066),
      900: Color(0xFF00543D),
    },
  );

  /// Get color for git status
  static Color gitStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'modified':
      case 'm':
        return warning;
      case 'added':
      case 'a':
        return success;
      case 'deleted':
      case 'd':
        return error;
      case 'renamed':
      case 'r':
        return info;
      case 'untracked':
      case '?':
        return textSecondary;
      default:
        return textTertiary;
    }
  }

  /// Get color for file type
  static Color fileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Color(0xFF0175C2);
      case '.js':
      case '.ts':
        return Color(0xFFF7DF1E);
      case '.py':
        return Color(0xFF3776AB);
      case '.java':
        return Color(0xFFED8B00);
      case '.cpp':
      case '.c':
        return Color(0xFF00599C);
      case '.html':
        return Color(0xFFE34F26);
      case '.css':
        return Color(0xFF1572B6);
      case '.json':
        return Color(0xFF000000);
      case '.md':
        return Color(0xFF083FA1);
      case '.xml':
        return Color(0xFFE37933);
      case '.yml':
      case '.yaml':
        return Color(0xFFCC1018);
      default:
        return textSecondary;
    }
  }

  /// Get semantic color for AI provider
  static Color aiProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
      case 'gpt':
        return Color(0xFF10A37F);
      case 'claude':
        return Color(0xFFCC785C);
      case 'gemini':
      case 'google':
        return Color(0xFF4285F4);
      case 'local':
      case 'on-device':
        return primary;
      default:
        return aiAccent;
    }
  }
}