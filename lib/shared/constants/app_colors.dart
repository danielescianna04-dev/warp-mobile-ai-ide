import 'package:flutter/material.dart';

/// Application color scheme inspired by Warp terminal
class AppColors {
  AppColors._();

  // Primary brand colors - Grayscale theme
  static const Color primary = Color(0xFF2A2A2A); // Dark gray
  static const Color primaryDark = Color(0xFF1A1A1A); // Darker gray
  static const Color primaryLight = Color(0xFF3A3A3A); // Lighter gray
  static const Color accent = Color(0xFF4A4A4A); // Medium gray accent

  // Background colors - Ultra dark theme
  static const Color background = Color(0xFF000000); // Pure black
  static const Color surface = Color(0xFF050607); // Almost black
  static const Color surfaceVariant = Color(0xFF0A0B0D); // Very dark grey

  // Text colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // Editor colors - Ultra dark theme
  static const Color editorBackground = Color(0xFF000000); // Pure black editor
  static const Color editorLineNumbers = Color(0xFF8B949E); // Slightly brighter for visibility
  static const Color editorSelection = Color(0xFF1E3A5F); // Darker blue selection
  static const Color editorCurrentLine = Color(0xFF0F1419); // Very dark highlight

  // Terminal colors - Ultra dark theme
  static const Color terminalBackground = Color(0xFF000000); // Pure black terminal
  static const Color terminalText = Color(0xFFFFFFFF); // Pure white text for max contrast
  static const Color terminalGreen = Color(0xFF00FF41); // Brighter green for visibility
  static const Color terminalYellow = Color(0xFFFFFF00); // Bright yellow
  static const Color terminalRed = Color(0xFFFF0051); // Bright red
  static const Color terminalBlue = Color(0xFFB0B0B0); // Light gray instead of blue
  static const Color terminalMagenta = Color(0xFFFF00FF); // Keep magenta bright
  static const Color terminalCyan = Color(0xFFE0E0E0); // Very light gray instead of cyan

  // Status colors
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF6A6A6A); // Gray for info

  // AI-specific colors - Purple/violet theme
  static const Color aiAccent = Color(0xFF8B5CF6); // Purple accent
  static const Color aiSecondary = Color(0xFF6366F1); // Indigo
  static const Color aiGradientStart = Color(0xFF8B5CF6); // Purple
  static const Color aiGradientEnd = Color(0xFF6366F1); // Indigo
  
  // Additional purple gradient colors
  static const Color purpleLight = Color(0xFFA855F7); // Light purple
  static const Color purpleMedium = Color(0xFF8B5CF6); // Medium purple
  static const Color purpleDark = Color(0xFF6D28D9); // Dark purple
  static const Color violetLight = Color(0xFF8B5CF6); // Light violet
  static const Color violetDark = Color(0xFF5B21B6); // Dark violet

  // Syntax highlighting colors
  static const Color syntaxKeyword = Color(0xFFFF7B72);
  static const Color syntaxString = Color(0xFFA5D6FF);
  static const Color syntaxComment = Color(0xFF8B949E);
  static const Color syntaxNumber = Color(0xFF79C0FF);
  static const Color syntaxFunction = Color(0xFFD2A8FF);
  static const Color syntaxClass = Color(0xFFFFA657);
  static const Color syntaxVariable = Color(0xFFFFA657);

  // Utility colors - Ultra dark theme
  static const Color divider = Color(0xFF1A1A1A); // Darker dividers
  static const Color border = Color(0xFF1A1A1A); // Darker borders
  static const Color shadow = Color(0x4D000000); // Stronger shadow for definition

  // Gradients - Purple/violet theme
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
  
  // Purple gradients for UI elements
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purpleLight, purpleDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient violetGradient = LinearGradient(
    colors: [violetLight, violetDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const RadialGradient purpleRadialGradient = RadialGradient(
    colors: [purpleMedium, purpleDark, Color(0xFF1A0B2E)],
    stops: [0.0, 0.7, 1.0],
    center: Alignment.topLeft,
    radius: 1.2,
  );
  
  // Subtle gradients for cards and surfaces
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A0B2E), Color(0xFF0F0815)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glowGradient = LinearGradient(
    colors: [
      Color(0x1A8B5CF6), // Purple with low opacity
      Color(0x0A6366F1), // Indigo with very low opacity
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Material color swatch for theme integration - Grayscale
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2A2A2A,
    <int, Color>{
      50: Color(0xFFF5F5F5),
      100: Color(0xFFE0E0E0),
      200: Color(0xFFBDBDBD),
      300: Color(0xFF9E9E9E),
      400: Color(0xFF757575),
      500: Color(0xFF2A2A2A),
      600: Color(0xFF252525),
      700: Color(0xFF202020),
      800: Color(0xFF1A1A1A),
      900: Color(0xFF0F0F0F),
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
        return Color(0xFF8A8A8A); // Gray for Dart
      case '.js':
      case '.ts':
        return Color(0xFFF7DF1E); // Keep yellow for JS/TS
      case '.py':
        return Color(0xFF9A9A9A); // Gray for Python
      case '.java':
        return Color(0xFFED8B00); // Keep orange for Java
      case '.cpp':
      case '.c':
        return Color(0xFF7A7A7A); // Gray for C/C++
      case '.html':
        return Color(0xFFE34F26); // Keep red for HTML
      case '.css':
        return Color(0xFF6A6A6A); // Gray for CSS
      case '.json':
        return Color(0xFFFFD700); // Gold for JSON on black background
      case '.md':
        return Color(0xFF7A7A7A); // Gray for Markdown
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
        return Color(0xFF6A6A6A); // Gray for Google/Gemini
      case 'local':
      case 'on-device':
        return primary; // Use our new gray primary
      default:
        return aiAccent;
    }
  }
}