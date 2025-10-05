# Guided App Creation Wizard - Preset System

## Overview

Il nuovo sistema di preset del wizard di creazione app fornisce un'esperienza guidata semplificata per creare applicazioni comuni. Gli utenti possono scegliere tra template predefiniti come "Note taking app", "AI chat app", "Airbnb UI clone", etc., oppure selezionare "Custom" per la configurazione manuale completa.

## Architecture

### Core Components

#### 1. `PresetAppsRepository` (`lib/core/wizard/preset_apps.dart`)
- **Scopo**: Gestisce le configurazioni predefinite per i tipi di app più comuni
- **Responsabilità**:
  - Definisce enum `PresetAppType` con i tipi disponibili
  - Mantiene la lista di `PresetAppConfig` con configurazioni complete
  - Fornisce metodi utility per recuperare configurazioni specifiche

#### 2. `PresetCard` (`lib/features/create_app/presentation/widgets/preset_card.dart`)
- **Scopo**: Widget riutilizzabile per visualizzare ogni preset
- **Features**:
  - Animazioni interattive di pressione e selezione
  - Design responsivo con gradienti e ombre
  - Badge di selezione con colori personalizzati per ogni preset
  - Support per feedback aptico

#### 3. `PresetSelectionStep` (`lib/features/create_app/presentation/steps/preset_selection_step.dart`)
- **Scopo**: Step principale per la selezione dei preset
- **Features**:
  - Layout a griglia responsive (2-4 colonne in base alla larghezza)
  - Animazioni graduate di entrata per ogni card
  - Header con titolo personalizzato ("Describe your app idea...")
  - Footer informativo per l'utente

### Flow Logic

#### Flusso Guidato (Preset Selezionato)
```
Nome App → Preset Selection → Summary Step
```

#### Flusso Personalizzato (Custom)
```
Nome App → App Type → Framework → Features → Template → Summary
```

### Data Model Extensions

Il modello `CreateAppWizardData` è stato esteso con:
- `selectedPreset`: Stringa che identifica il preset selezionato
- `isPresetSelected`: Getter per verificare se è stato selezionato un preset
- `isCustomFlow`: Getter per verificare se è un flusso personalizzato

## Available Presets

### 1. Note Taking App
- **Framework**: Flutter
- **Features**: markdown, cloud_sync, search, tags, offline_mode
- **Template**: note_app_template
- **Color**: Green (#4CAF50)

### 2. AI Chat App
- **Framework**: Flutter  
- **Features**: ai_integration, chat_history, voice_input, markdown_support, themes
- **Template**: ai_chat_template
- **Color**: Blue (#2196F3)

### 3. Airbnb UI Clone
- **Framework**: Flutter
- **Features**: maps, search, filters, booking, reviews, payments
- **Template**: airbnb_clone_template
- **Color**: Deep Orange (#FF5722)

### 4. Wordle Clone
- **Framework**: Flutter
- **Features**: game_logic, statistics, animations, daily_challenge, offline_play
- **Template**: wordle_clone_template
- **Color**: Purple (#9C27B0)

### 5. Todo App
- **Framework**: Flutter
- **Features**: task_management, categories, notifications, calendar, sync
- **Template**: todo_app_template
- **Color**: Orange (#FF9800)

### 6. Weather App
- **Framework**: Flutter
- **Features**: weather_api, location, forecasts, maps, widgets
- **Template**: weather_app_template
- **Color**: Teal (#03DAC6)

### 7. E-commerce App
- **Framework**: Flutter
- **Features**: product_catalog, cart, payments, orders, reviews, wishlist
- **Template**: ecommerce_template
- **Color**: Pink (#E91E63)

### 8. Music Player
- **Framework**: Flutter
- **Features**: audio_player, playlists, equalizer, streaming, lyrics
- **Template**: music_player_template
- **Color**: Deep Purple (#673AB7)

### 9. Custom
- **Framework**: User-defined
- **Features**: User-defined
- **Template**: User-defined
- **Color**: Blue Grey (#607D8B)

## Usage

### For Users
1. Avvia il wizard dall'icona "🚀 Crea App" nella sidebar
2. Inserisci il nome dell'app
3. Scegli un preset dalla griglia o seleziona "Custom" per configurazione manuale
4. Se selezioni un preset, vai direttamente al riepilogo
5. Se selezioni "Custom", procedi con la configurazione completa

### For Developers

#### Aggiungere un Nuovo Preset
1. Aggiungi il tipo all'enum `PresetAppType` in `preset_apps.dart`
2. Aggiungi la configurazione alla lista `presets` in `PresetAppsRepository`
3. La nuova opzione apparirà automaticamente nella griglia

```dart
enum PresetAppType {
  // ... existing types
  newAppType,
}

// In PresetAppsRepository.presets
PresetAppConfig(
  type: PresetAppType.newAppType,
  name: 'New App Type',
  description: 'Description of the new app type',
  icon: Icons.new_icon,
  appType: 'mobile',
  framework: 'flutter',
  features: ['feature1', 'feature2'],
  templateId: 'new_template_id',
  accentColor: Color(0xFF1234AB),
),
```

#### Testing
- Usa `TestPresetStepPage` per testare il preset selection in isolazione
- Includi il debug button per ispezionare lo stato corrente
- Naviga via `TestPresetRoute.route()`

## Performance Considerations

- **Lazy Loading**: Le configurazioni dei preset sono definite come costanti statiche
- **Animazioni Efficienti**: Usa `AnimatedBuilder` e `SingleTickerProviderStateMixin`
- **Memory Management**: Disposing degli animation controller nel `dispose()`
- **Responsive Design**: Layout dinamico basato sui vincoli della schermata

## Accessibility

- **Haptic Feedback**: Feedback tattile per selezione e pressione
- **High Contrast**: Bordi e colori contrastanti per la selezione
- **Semantic Labels**: Supporto per screen reader (da implementare)
- **Keyboard Navigation**: Navigation con tastiera (da implementare)

## Next Steps

1. **Test di Integrazione**: Aggiungere test per verificare il flusso end-to-end
2. **Localizzazione**: Traduzione delle descrizioni in multiple lingue
3. **Analytics**: Tracking per capire quali preset sono più popolari
4. **Template System**: Implementazione reale dei template per la generazione del codice

## API Reference

### PresetAppsRepository
- `static List<PresetAppConfig> getPresetApps()`: Ottiene tutti i preset (escluso custom)
- `static PresetAppConfig getCustomPreset()`: Ottiene il preset custom
- `static PresetAppConfig? getConfig(PresetAppType type)`: Ottiene configurazione specifica
- `static bool isCustom(PresetAppType? type)`: Verifica se è custom

### CreateAppWizardProvider
- `void selectPreset(PresetAppType presetType)`: Seleziona un preset e configura automaticamente
- `void nextStep()`: Navigazione intelligente (salta step se preset selezionato)

### PresetCard
- `PresetCard({required config, required isSelected, required onTap})`: Card interattiva per preset
- Parametri opzionali: `width`, `height` per controllo dimensioni