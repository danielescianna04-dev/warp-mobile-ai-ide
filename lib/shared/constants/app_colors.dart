import 'package:flutter/material.dart';

/// VibeCode Minimal Purple - Palette di colori con supporto Light & Dark Mode
/// Basata su filosofia Apple con viola brand invariante
class AppColors {
  AppColors._();

  // ===== VIOLA BRAND - IDENTICI IN ENTRAMBE LE MODALITÀ =====
  static const Color primary = Color(0xFF6F5CFF); // Logo, CTA, link principali
  static const Color primaryTint = Color(0xFFB6ADFF); // Hover leggeri, icone outline
  static const Color primaryShade = Color(0xFF5946D6); // Stati pressed, accenti scuri
  
  // ===== LIGHT MODE COLORS =====
  static const Color lightBackground = Color(0xFFFFFFFF); // 90% bianco puro
  static const Color lightBackgroundAlt = Color(0xFFF9FAFB); // Alternativa sezione
  static const Color lightSurface = Color(0xFFFFFFFF); // Cards con shadow soft
  static const Color lightTitleText = Color(0xFF1E1E1F); // Nero soft Apple
  static const Color lightBodyText = Color(0xFF6E6E73); // Grigio leggibile
  static const Color lightBorder = Color(0xFFE5E5EA); // Bordi sottili
  
  // ===== DARK MODE COLORS =====
  static const Color darkBackground = Color(0xFF090A0B); // Nero profondo
  static const Color darkSurface = Color(0xFF1C1C1E); // Grigio molto scuro cards
  static const Color darkTitleText = Color(0xFFEDEDED); // Bianco soft
  static const Color darkBodyText = Color(0xFF9CA3AF); // Grigio chiaro
  static const Color darkBorder = Color(0xFF2C2C2E); // Bordi più visibili

  // ===== DYNAMIC COLORS - Variano con il tema =====
  // Questi vengono calcolati dinamicamente tramite brightness
  static Color background(Brightness brightness) => 
      brightness == Brightness.light ? lightBackground : darkBackground;
      
  static Color backgroundAlt(Brightness brightness) => 
      brightness == Brightness.light ? lightBackgroundAlt : darkBackground;
      
  static Color surface(Brightness brightness) => 
      brightness == Brightness.light ? lightSurface : darkSurface;
      
  static Color titleText(Brightness brightness) => 
      brightness == Brightness.light ? lightTitleText : darkTitleText;
      
  static Color bodyText(Brightness brightness) => 
      brightness == Brightness.light ? lightBodyText : darkBodyText;
      
  static Color border(Brightness brightness) => 
      brightness == Brightness.light ? lightBorder : darkBorder;

  // ===== COMPATIBILITÀ CON TEMI LEGACY =====
  // Manteniamo alcuni alias per non rompere codice esistente
  @Deprecated('Use background(brightness) instead')
  static const Color oldBackground = Color(0xFF090A0B);
  @Deprecated('Use surface(brightness) instead')
  static const Color oldSurface = Color(0xFF1C1C1E);
  @Deprecated('Use titleText(brightness) instead')
  static const Color textPrimary = Color(0xFFEDEDED);
  @Deprecated('Use bodyText(brightness) instead')
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6E7681);
  
  // ===== ALIAS PER COMPATIBILITÀ =====
  /// Alias per 'primary' - per compatibilità con codice esistente
  static const Color accent = primary;
  
  /// Surface variant dinamico
  static Color surfaceVariant(Brightness brightness) =>
      brightness == Brightness.light 
          ? const Color(0xFFF5F5F7) // Grigio molto chiaro per light
          : const Color(0xFF2C2C2E); // Grigio per dark
          
  /// Editor background dinamico
  static Color editorBackground(Brightness brightness) =>
      brightness == Brightness.light
          ? lightBackground  // Bianco per light mode
          : const Color(0xFF1A1A1A); // Grigio scuro per dark mode editor
          
  /// Editor line numbers dinamico
  static Color editorLineNumbers(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0xFF6E6E73) // Grigio per light
          : const Color(0xFF8B949E); // Grigio chiaro per dark
  
  // Terminal colors - Mantengono stile attuale
  static const Color terminalBackground = Color(0xFF000000);
  static const Color terminalText = Color(0xFFFFFFFF);
  static const Color terminalGreen = Color(0xFF00FF41);
  static const Color terminalYellow = Color(0xFFFFFF00);
  static const Color terminalRed = Color(0xFFFF0051);
  static const Color terminalBlue = Color(0xFFB0B0B0);
  static const Color terminalMagenta = Color(0xFFFF00FF);
  static const Color terminalCyan = Color(0xFFE0E0E0);

  // ===== STATUS COLORS - Sempre visibili =====
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF6A6A6A);
  
  // ===== AI COLORS - Deprecati, usa primary =====
  @Deprecated('Use primary instead')
  static const Color aiAccent = primary;
  @Deprecated('Use primaryTint instead')
  static const Color aiSecondary = primaryTint;
  @Deprecated('Use primary instead')
  static const Color purpleMedium = primary;
  @Deprecated('Use primaryTint instead')
  static const Color purpleLight = primaryTint;
  @Deprecated('Use primaryShade instead')
  static const Color purpleDark = primaryShade;
  @Deprecated('Use primaryTint instead')
  static const Color violetLight = primaryTint;
  @Deprecated('Use primaryShade instead')
  static const Color violetDark = primaryShade;

  // ===== SYNTAX HIGHLIGHTING - Invariate =====
  static const Color syntaxKeyword = Color(0xFFFF7B72);
  static const Color syntaxString = Color(0xFFA5D6FF);
  static const Color syntaxComment = Color(0xFF8B949E);
  static const Color syntaxNumber = Color(0xFF79C0FF);
  static const Color syntaxFunction = Color(0xFFD2A8FF);
  static const Color syntaxClass = Color(0xFFFFA657);
  static const Color syntaxVariable = Color(0xFFFFA657);
  
  // ===== UTILITY COLORS - Dinamici =====
  static Color divider(Brightness brightness) => border(brightness);
  static Color shadow(Brightness brightness) => 
      brightness == Brightness.light 
          ? const Color(0x0A000000) // rgba(0,0,0,0.04) per light
          : const Color(0x4D000000); // Shadow più forte per dark

  // ===== GRADIENTI HERO DINAMICI =====
  /// Hero gradient per light mode
  static const RadialGradient lightHeroGradient = RadialGradient(
    center: Alignment(0.0, -0.6), // 50% 20% come da specifiche
    radius: 1.2, // 60% 60%
    colors: [
      primaryTint, // #B6ADFF 0%
      primary,     // #6F5CFF 35%
      lightBackground, // #FFFFFF 80%
    ],
    stops: [0.0, 0.35, 0.8],
  );
  
  /// Hero gradient per dark mode
  static const RadialGradient darkHeroGradient = RadialGradient(
    center: Alignment(0.0, -0.6),
    radius: 1.2,
    colors: [
      primaryShade,    // #5946D6 0%
      primary,         // #6F5CFF 35%
      darkBackground,  // #090A0B 80%
    ],
    stops: [0.0, 0.35, 0.8],
  );
  
  /// Metodo helper per ottenere il gradient giusto
  static RadialGradient heroGradient(Brightness brightness) =>
      brightness == Brightness.light ? lightHeroGradient : darkHeroGradient;
  
  // ===== GRADIENTI LEGACY - Deprecati =====
  @Deprecated('Use heroGradient(brightness) instead')
  static const LinearGradient aiGradient = LinearGradient(
    colors: [primary, primaryTint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  @Deprecated('Use primary color directly for buttons')
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryShade],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  @Deprecated('Use primary color directly')
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primary, primaryShade],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ===== GRADIENTI CARD E GLOW =====
  /// Gradient sottile per card - si adatta al tema
  static LinearGradient cardGradient(Brightness brightness) => 
      brightness == Brightness.light
          ? LinearGradient(
              colors: [lightSurface, lightBackgroundAlt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [darkSurface, const Color(0xFF0F0815)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
  
  /// Glow effect per elementi interattivi
  static LinearGradient glowGradient(Brightness brightness) => 
      LinearGradient(
        colors: [
          primary.withValues(alpha: 0.1), // Purple con bassa opacity
          primary.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ===== COLORSCHEME COMPLETI =====
  /// ColorScheme per Light Mode
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primaryTint,
    onSecondary: lightTitleText,
    tertiary: primaryShade,
    onTertiary: Colors.white,
    surface: lightSurface,
    onSurface: lightTitleText,
    background: lightBackground,
    onBackground: lightTitleText,
    error: error,
    onError: Colors.white,
    outline: lightBorder,
    shadow: Color(0x0A000000),
    inverseSurface: darkSurface,
    onInverseSurface: darkTitleText,
  );
  
  /// ColorScheme per Dark Mode
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primaryTint,
    onSecondary: darkBackground,
    tertiary: primaryShade,
    onTertiary: Colors.white,
    surface: darkSurface,
    onSurface: darkTitleText,
    background: darkBackground,
    onBackground: darkTitleText,
    error: error,
    onError: Colors.white,
    outline: darkBorder,
    shadow: Color(0x4D000000),
    inverseSurface: lightSurface,
    onInverseSurface: lightTitleText,
  );
  
  /// Material color swatch per compatibilità
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF6F5CFF,
    <int, Color>{
      50: Color(0xFFF4F2FF), // Molto chiaro
      100: Color(0xFFE8E4FF), // Chiaro
      200: Color(0xFFD1C8FF), // 
      300: Color(0xFFB6ADFF), // primaryTint
      400: Color(0xFF9B8CFF), // 
      500: Color(0xFF6F5CFF), // primary
      600: Color(0xFF5946D6), // primaryShade
      700: Color(0xFF4936B8), // 
      800: Color(0xFF3A2999), // 
      900: Color(0xFF2B1F7A), // Molto scuro
    },
  );

  // ===== METODI HELPER =====
  /// Clamp opacity value between 0.0 and 1.0 to prevent painting errors
  static double safeOpacity(double opacity) {
    return opacity.clamp(0.0, 1.0);
  }
  
  /// Get primary color with safe opacity
  static Color primaryWithOpacity(double opacity) {
    return primary.withValues(alpha: safeOpacity(opacity));
  }
  
  /// Get primaryTint color with safe opacity
  static Color primaryTintWithOpacity(double opacity) {
    return primaryTint.withValues(alpha: safeOpacity(opacity));
  }
  
  /// Get primaryShade color with safe opacity
  static Color primaryShadeWithOpacity(double opacity) {
    return primaryShade.withValues(alpha: safeOpacity(opacity));
  }
  
  /// Get tech green color with safe opacity (for matrix/terminal effects)
  static Color techGreenWithOpacity(double opacity) {
    return const Color(0xFF00FF88).withValues(alpha: safeOpacity(opacity));
  }
  
  /// Get tech blue color with safe opacity (for circuit effects)
  static Color techBlueWithOpacity(double opacity) {
    return const Color(0xFF0088FF).withValues(alpha: safeOpacity(opacity));
  }
  
  /// Get tech red color with safe opacity (for glitch effects)
  static Color techRedWithOpacity(double opacity) {
    return const Color(0xFFFF0088).withValues(alpha: safeOpacity(opacity));
  }
  
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
        return const Color(0xFF9CA3AF); // textSecondary equivalente
      default:
        return textTertiary;
    }
  }

  /// Get color for file type
  static Color fileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return const Color(0xFF8A8A8A);
      case '.js':
      case '.ts':
        return const Color(0xFFF7DF1E);
      case '.py':
        return const Color(0xFF9A9A9A);
      case '.java':
        return const Color(0xFFED8B00);
      case '.cpp':
      case '.c':
        return const Color(0xFF7A7A7A);
      case '.html':
        return const Color(0xFFE34F26);
      case '.css':
        return const Color(0xFF6A6A6A);
      case '.json':
        return const Color(0xFFFFD700);
      case '.md':
        return const Color(0xFF7A7A7A);
      case '.xml':
        return const Color(0xFFE37933);
      case '.yml':
      case '.yaml':
        return const Color(0xFFCC1018);
      default:
        return const Color(0xFF9CA3AF); // textSecondary equivalente
    }
  }

  /// Get semantic color for AI provider
  static Color aiProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
      case 'gpt':
        return const Color(0xFF10A37F);
      case 'claude':
        return const Color(0xFFCC785C);
      case 'gemini':
      case 'google':
        return const Color(0xFF6A6A6A);
      case 'local':
      case 'on-device':
        return primary;
      default:
        return primary; // Usa il nostro viola brand
    }
  }
  
  /// Chat selection background color (dynamic)
  static Color chatSelection(Brightness brightness) => 
      brightness == Brightness.light
          ? primary.withValues(alpha: 0.1)
          : primary.withValues(alpha: 0.15);
  
  // ===== QUICK ACCESS METHODS =====
  /// Ottieni il colore di background corretto per il context
  static Color getBackground(BuildContext context) => 
      background(Theme.of(context).brightness);
      
  /// Ottieni il colore di surface corretto per il context
  static Color getSurface(BuildContext context) => 
      surface(Theme.of(context).brightness);
      
  /// Ottieni il colore del testo titolo corretto per il context
  static Color getTitleText(BuildContext context) => 
      titleText(Theme.of(context).brightness);
      
  /// Ottieni il colore del testo body corretto per il context
  static Color getBodyText(BuildContext context) => 
      bodyText(Theme.of(context).brightness);
      
  /// Ottieni il hero gradient corretto per il context
  static RadialGradient getHeroGradient(BuildContext context) => 
      heroGradient(Theme.of(context).brightness);
      
  /// Ottieni surfaceVariant corretto per il context
  static Color getSurfaceVariant(BuildContext context) =>
      surfaceVariant(Theme.of(context).brightness);
      
  /// Ottieni editorBackground corretto per il context
  static Color getEditorBackground(BuildContext context) =>
      editorBackground(Theme.of(context).brightness);
      
  /// Ottieni editorLineNumbers corretto per il context
  static Color getEditorLineNumbers(BuildContext context) =>
      editorLineNumbers(Theme.of(context).brightness);
}
