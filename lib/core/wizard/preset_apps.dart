import 'package:flutter/material.dart';

/// Configurazione predefinita per tipi di app comuni
enum PresetAppType {
  noteTaking,
  aiChat,
  airbnbClone,
  wordleClone,
  todoApp,
  weatherApp,
  ecommerceApp,
  musicPlayer,
  custom,
}

/// Configurazione completa di un preset di app
class PresetAppConfig {
  final PresetAppType type;
  final String name;
  final String description;
  final IconData icon;
  final String appType;
  final String framework;
  final List<String> features;
  final String? templateId;
  final Color accentColor;

  const PresetAppConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.appType,
    required this.framework,
    required this.features,
    this.templateId,
    required this.accentColor,
  });
}

/// Repository di configurazioni predefinite per le app
class PresetAppsRepository {
  static const List<PresetAppConfig> presets = [
    // Note Taking App
    PresetAppConfig(
      type: PresetAppType.noteTaking,
      name: 'Note taking app',
      description: 'App per prendere e organizzare note con markdown e sincronizzazione cloud',
      icon: Icons.note_alt_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['markdown', 'cloud_sync', 'search', 'tags', 'offline_mode'],
      templateId: 'note_app_template',
      accentColor: Color(0xFF4CAF50),
    ),

    // AI Chat App
    PresetAppConfig(
      type: PresetAppType.aiChat,
      name: 'AI chat app',
      description: 'Applicazione di chat con intelligenza artificiale e supporto multi-modello',
      icon: Icons.chat_bubble_outline,
      appType: 'mobile',
      framework: 'flutter',
      features: ['ai_integration', 'chat_history', 'voice_input', 'markdown_support', 'themes'],
      templateId: 'ai_chat_template',
      accentColor: Color(0xFF2196F3),
    ),

    // Airbnb Clone
    PresetAppConfig(
      type: PresetAppType.airbnbClone,
      name: 'Airbnb UI clone',
      description: 'Clone della UI di Airbnb con ricerca, filtri e prenotazioni',
      icon: Icons.home_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['maps', 'search', 'filters', 'booking', 'reviews', 'payments'],
      templateId: 'airbnb_clone_template',
      accentColor: Color(0xFFFF5722),
    ),

    // Wordle Clone
    PresetAppConfig(
      type: PresetAppType.wordleClone,
      name: 'Wordle clone',
      description: 'Gioco di parole simile a Wordle con statistiche e modalità multiplayer',
      icon: Icons.games_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['game_logic', 'statistics', 'animations', 'daily_challenge', 'offline_play'],
      templateId: 'wordle_clone_template',
      accentColor: Color(0xFF9C27B0),
    ),

    // Todo App
    PresetAppConfig(
      type: PresetAppType.todoApp,
      name: 'Todo app',
      description: 'Applicazione per la gestione delle attività con categorie e promemoria',
      icon: Icons.check_box_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['task_management', 'categories', 'notifications', 'calendar', 'sync'],
      templateId: 'todo_app_template',
      accentColor: Color(0xFFFF9800),
    ),

    // Weather App
    PresetAppConfig(
      type: PresetAppType.weatherApp,
      name: 'Weather app',
      description: 'App meteo con previsioni dettagliate e mappe interattive',
      icon: Icons.wb_sunny_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['weather_api', 'location', 'forecasts', 'maps', 'widgets'],
      templateId: 'weather_app_template',
      accentColor: Color(0xFF03DAC6),
    ),

    // E-commerce App
    PresetAppConfig(
      type: PresetAppType.ecommerceApp,
      name: 'E-commerce app',
      description: 'Applicazione di e-commerce con catalogo prodotti e carrello',
      icon: Icons.shopping_cart_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['product_catalog', 'cart', 'payments', 'orders', 'reviews', 'wishlist'],
      templateId: 'ecommerce_template',
      accentColor: Color(0xFFE91E63),
    ),

    // Music Player
    PresetAppConfig(
      type: PresetAppType.musicPlayer,
      name: 'Music player',
      description: 'Player musicale con playlist, equalizzatore e streaming',
      icon: Icons.library_music_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: ['audio_player', 'playlists', 'equalizer', 'streaming', 'lyrics'],
      templateId: 'music_player_template',
      accentColor: Color(0xFF673AB7),
    ),

    // Custom - sempre ultimo
    PresetAppConfig(
      type: PresetAppType.custom,
      name: 'Custom',
      description: 'Crea la tua app personalizzata con configurazione manuale completa',
      icon: Icons.settings_outlined,
      appType: 'mobile',
      framework: 'flutter',
      features: [],
      accentColor: Color(0xFF607D8B),
    ),
  ];

  /// Ottiene la configurazione per un tipo specifico
  static PresetAppConfig? getConfig(PresetAppType type) {
    try {
      return presets.firstWhere((preset) => preset.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Ottiene tutti i preset escluso custom
  static List<PresetAppConfig> getPresetApps() {
    return presets.where((preset) => preset.type != PresetAppType.custom).toList();
  }

  /// Ottiene il preset custom
  static PresetAppConfig getCustomPreset() {
    return presets.firstWhere((preset) => preset.type == PresetAppType.custom);
  }

  /// Verifica se un preset è custom
  static bool isCustom(PresetAppType? type) {
    return type == null || type == PresetAppType.custom;
  }
}