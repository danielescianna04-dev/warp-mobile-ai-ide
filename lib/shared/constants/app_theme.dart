import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Temi per VibeCode Minimal Purple
/// Segue le specifiche Apple-style con viola brand invariante
class AppTheme {
  AppTheme._();

  // ===== LIGHT THEME =====
  static ThemeData get lightTheme {
    return ThemeData(
      // ColorScheme base
      colorScheme: AppColors.lightScheme,
      useMaterial3: true,
      
      // Typography - Gerarchie Apple-style
      textTheme: _buildLightTextTheme(),
      primaryTextTheme: _buildLightTextTheme(),
      
      // AppBar con stile minimale
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTitleText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.lightTitleText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card Theme - Stile Apple minimale
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadow(Brightness.light),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // ElevatedButton - Viola brand invariante
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightBodyText,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          // Hover/pressed states
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryShade;
            }
            if (states.contains(MaterialState.hovered)) {
              return AppColors.primaryShade;
            }
            if (states.contains(MaterialState.disabled)) {
              return AppColors.lightBodyText;
            }
            return AppColors.primary;
          }),
        ),
      ),

      // OutlinedButton Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // TextButton Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBackgroundAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          color: AppColors.lightBodyText.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.lightBackground,

      // Splash/Ripple colors
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightBodyText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.lightBodyText,
        size: 20,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 20,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightBorder,
        circularTrackColor: AppColors.lightBorder,
      ),
    );
  }

  // ===== DARK THEME =====
  static ThemeData get darkTheme {
    return ThemeData(
      // ColorScheme base
      colorScheme: AppColors.darkScheme,
      useMaterial3: true,
      
      // Typography - Gerarchie Apple-style
      textTheme: _buildDarkTextTheme(),
      primaryTextTheme: _buildDarkTextTheme(),
      
      // AppBar con stile minimale dark
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTitleText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.darkTitleText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme - Dark mode
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadow(Brightness.dark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // ElevatedButton - Viola brand invariante (IDENTICO)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // IDENTICO al light mode
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.darkBodyText,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          // Hover/pressed states - IDENTICI
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryShade; // IDENTICO
            }
            if (states.contains(MaterialState.hovered)) {
              return AppColors.primaryShade; // IDENTICO
            }
            if (states.contains(MaterialState.disabled)) {
              return AppColors.darkBodyText;
            }
            return AppColors.primary; // IDENTICO
          }),
        ),
      ),

      // OutlinedButton Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, // IDENTICO
          side: const BorderSide(color: AppColors.primary, width: 1), // IDENTICO
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // TextButton Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary, // IDENTICO
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2), // IDENTICO
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          color: AppColors.darkBodyText.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder, // Flip completo: E5E5EA → 2C2C2E
        thickness: 1,
        space: 1,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Splash/Ripple colors - IDENTICI
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary, // IDENTICO
        unselectedItemColor: AppColors.darkBodyText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkBodyText,
        size: 20,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary, // IDENTICO
        size: 20,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary, // IDENTICO
        linearTrackColor: AppColors.darkBorder,
        circularTrackColor: AppColors.darkBorder,
      ),
    );
  }

  // ===== TEXT THEMES - APPLE STYLE HIERARCHY =====
  
  static TextTheme _buildLightTextTheme() {
    return const TextTheme(
      // Display styles
      displayLarge: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      
      // Headline styles - Per titoli sezione
      headlineLarge: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: AppColors.lightTitleText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      
      // Body styles - Testo principale
      bodyLarge: TextStyle(
        color: AppColors.lightBodyText, // #6E6E73 - Grigio leggibile
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightBodyText,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.lightBodyText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        color: AppColors.lightBodyText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        color: AppColors.lightBodyText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        color: AppColors.lightBodyText,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  static TextTheme _buildDarkTextTheme() {
    return const TextTheme(
      // Display styles - FLIP COMPLETO
      displayLarge: TextStyle(
        color: AppColors.darkTitleText, // #EDEDED - Near-white
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: AppColors.darkTitleText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      
      // Body styles - FLIP COMPLETO
      bodyLarge: TextStyle(
        color: AppColors.darkBodyText, // #9CA3AF - Grigio chiaro
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkBodyText,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.darkBodyText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        color: AppColors.darkBodyText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        color: AppColors.darkBodyText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        color: AppColors.darkBodyText,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  // ===== HELPER METHODS =====
  
  /// Ottieni il tema corretto basato sulla brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// Ottieni il colore per gli shadow in base al tema
  static Color getShadowColor(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0x0A000000) // rgba(0,0,0,0.04)
        : const Color(0x4D000000); // Shadow più forte
  }

  /// Ottieni l'elevation corretta per il tema
  static double getElevation(Brightness brightness) {
    return brightness == Brightness.light ? 0 : 0; // Sempre flat per stile minimale
  }
}