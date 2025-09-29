import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

/// Provider per la gestione del tema VibeCode Minimal Purple
/// Supporta Light Mode, Dark Mode e System (Auto)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Modalità tema corrente
  ThemeMode get themeMode => _themeMode;

  /// Brightness corrente basato su sistema/manuale
  Brightness get brightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  /// Check se è dark mode attivo
  bool get isDarkMode => brightness == Brightness.dark;

  /// Check se è light mode attivo
  bool get isLightMode => brightness == Brightness.light;

  /// Check se segue il sistema
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Cambia il tema
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  /// Toggle tra light e dark (ignora system)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Switch a modalità system
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Switch a light mode
  Future<void> useLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Switch a dark mode
  Future<void> useDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Carica le preferenze dal storage
  Future<void> _loadThemeFromPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final String? savedTheme = _prefs?.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Errore caricamento tema: $e');
      // Fallback a system mode
      _themeMode = ThemeMode.system;
    }
  }

  /// Salva le preferenze nel storage
  Future<void> _saveThemeToPrefs() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      String themeString;
      switch (_themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await _prefs?.setString(_themeKey, themeString);
      debugPrint('💾 Tema salvato: $themeString');
    } catch (e) {
      debugPrint('⚠️ Errore salvataggio tema: $e');
    }
  }

  /// Ottieni string human-readable per il tema corrente
  String get currentThemeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System (${brightness == Brightness.light ? 'Light' : 'Dark'})';
    }
  }

  /// Ottieni l'icona appropriata per il tema corrente
  IconData get currentThemeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  /// Reset alle impostazioni di default
  Future<void> resetToDefault() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Debug info
  void debugPrintThemeInfo() {
    debugPrint('''
🎨 VIBECORE THEME INFO:
├─ Mode: $_themeMode
├─ Brightness: $brightness
├─ Display: $currentThemeDisplayName
└─ Icon: $currentThemeIcon
    ''');
  }
}

/// Extension helper per context
extension ThemeProviderExtension on BuildContext {
  /// Quick access al ThemeProvider
  ThemeProvider get themeProvider => 
      Provider.of<ThemeProvider>(this, listen: false);

  /// Quick access al ThemeProvider con listener
  ThemeProvider get watchTheme => 
      Provider.of<ThemeProvider>(this, listen: true);
}

