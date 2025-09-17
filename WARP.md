# WARP.md

Questo file fornisce linee guida per WARP (warp.dev) quando si lavora con il codice in questo repository.

## Panoramica del Progetto

**Warp Mobile AI IDE** è un IDE mobile-first che porta la potenza di Warp e l'AI multimodello direttamente su iPhone e Android. Permette agli sviluppatori di programmare, testare e collaborare interamente dal telefono, eliminando i vincoli del desktop.

## Architettura

```
Warp Mobile AI IDE
├── Frontend: Flutter (Dart 3.2.6+)
├── State Management: Provider + Bloc pattern
├── AI Integration: OpenAI, Claude, Gemini + On-device TensorFlow Lite
├── Version Control: Git + GitHub API integration
├── Terminal: Process emulation con shell integration
├── Storage: Hive + Secure Storage + SharedPreferences
├── Code Editor: flutter_code_editor con syntax highlighting
└── Testing: Unit + Integration + Widget tests
```

### Struttura delle Directory Principali

- `lib/` - Codice sorgente Flutter
  - `main.dart` - Entry point dell'applicazione
  - `core/` - Logica di business e servizi (AI, GitHub, Terminal)
  - `features/` - Funzionalità principali (Editor, Terminal, Preview, Collaboration)
  - `shared/` - Componenti UI riutilizzabili, utilities, costanti
- `android/` - Configurazione piattaforma Android
- `ios/` - Configurazione piattaforma iOS
- `test/` - Test automatizzati
- `scripts/` - Script di automazione

## Comandi Essenziali

### Sviluppo

```bash
# Installare le dipendenze
flutter pub get

# Avviare in modalità debug
flutter run

# Avviare su dispositivo specifico
flutter run -d <device-id>

# Build per release
flutter build apk        # Android
flutter build ios        # iOS

# Pulire cache e build
flutter clean
flutter pub get
```

### Script di Sviluppo (Raccomandato)

Il progetto include script bash ottimizzati in `scripts/dev.sh`:

```bash
# Setup completo ambiente sviluppo
./scripts/dev.sh setup

# Avviare server di sviluppo con hot reload
./scripts/dev.sh dev-run

# Pulire progetto completamente
./scripts/dev.sh clean

# Analisi completa (lint + test + format)
./scripts/dev.sh analyze

# Preparare build di release
./scripts/dev.sh prepare-release

# Aiuto per tutti i comandi disponibili
./scripts/dev.sh help
```

### Testing

```bash
# Eseguire tutti i test
flutter test

# Test con coverage
flutter test --coverage

# Test di integrazione
flutter test integration_test/

# Analisi del codice
flutter analyze

# Formattazione del codice
dart format lib/ test/ --set-exit-if-changed
```

### Gestione Dipendenze

```bash
# Aggiungere una dipendenza
flutter pub add package_name

# Aggiungere una dipendenza di sviluppo
flutter pub add dev:package_name

# Aggiornare dipendenze
flutter pub upgrade

# Verificare dipendenze obsolete
flutter pub outdated
```

### Code Generation

Il progetto usa code generation per Hive databases e JSON serialization:

```bash
# Generare codice (per Hive, JSON serialization)
flutter packages pub run build_runner build

# Generare codice in watch mode
flutter packages pub run build_runner watch

# Pulire e rigenerare
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs

# Script alternativo (raccomandato)
./scripts/dev.sh codegen
```

**File generati automaticamente**: `*.g.dart`, `*.freezed.dart` (esclusi da Git)

## Configurazione Ambiente

### Requisiti di Sistema

```bash
# Flutter SDK
Flutter 3.16.0+ (channel stable)

# Dart SDK  
Dart 3.2.6+ 

# Piattaforme
- Android SDK 21+ (Android 5.0+)
- iOS 12.0+ / Xcode 15+
- macOS per sviluppo iOS
```

### IDE e Strumenti

```bash
# Editor consigliati
- VS Code con Flutter/Dart extensions
- Android Studio con Flutter plugin
- IntelliJ IDEA

# Strumenti essenziali
- Git
- CocoaPods (per iOS)
- Java 11+ (per Android)
```

### Configurazione VS Code

Il progetto include configurazione ottimizzata VS Code:

**Launch Configurations** (`.vscode/launch.json`):
- `Debug (Development)` - Debug con Chrome
- `Profile` - Modalità profiling
- `Release` - Build di release
- `Debug Tests` - Debug dei test

**Settings** (`.vscode/settings.json`):
- Format on save abilitato
- Line length: 100 caratteri  
- Esclusioni file generate (*.g.dart, *.freezed.dart)
- Dart-specific configurations

### Variabili d'Ambiente

```bash
# File .env (da creare nella root del progetto)
OPENAI_API_KEY="your-openai-api-key"
ANTHROPIC_API_KEY="your-claude-api-key"  
GOOGLE_AI_API_KEY="your-gemini-api-key"
GITHUB_CLIENT_ID="your-github-oauth-app-id"
GITHUB_CLIENT_SECRET="your-github-oauth-secret"

# Environment per development/testing
ENVIRONMENT="development"
DEBUG_MODE="true"
LOG_LEVEL="debug"
```

**Nota**: Il file `.env` non esiste ancora nel progetto. Crealo manualmente nella root del progetto con le tue API keys prima di avviare l'app.

## Schema dell'Architettura

L'applicazione segue il pattern di Clean Architecture con separazione chiara dei layer:

### 1. Presentation Layer (`lib/features/`)
- **Editor**: Interfaccia di editing del codice con syntax highlighting
- **Terminal**: Emulatore di terminale con supporto comandi
- **Preview**: Anteprima e testing in-app per progetti Flutter/Web
- **Collaboration**: Integrazione GitHub per version control

### 2. Domain Layer (`lib/core/`)
- **AI Services**: Astrazione per modelli AI multipli (OpenAI, Claude, Gemini)
- **GitHub Integration**: Operazioni Git e API GitHub
- **Terminal Engine**: Elaborazione ed esecuzione comandi
- **File System**: Gestione file e progetti

### 3. Data Layer
- **Local Storage**: Hive per dati strutturati, Secure Storage per API keys
- **Network**: HTTP client per API esterne
- **Caching**: Strategie di caching per AI responses e file

## Integrazione AI

### Modelli Supportati

```dart
// Servizi AI disponibili
enum AIProvider {
  openai,    // ChatGPT-4, GPT-3.5
  claude,    // Claude-3 (Anthropic)
  gemini,    // Gemini Pro (Google)
  onDevice,  // TensorFlow Lite local models
}
```

### Funzionalità AI

- **Code Generation**: Generazione di codice da prompt naturale
- **Code Explanation**: Spiegazione di codice esistente
- **Debugging**: Assistenza nel debug con analisi errori
- **Refactoring**: Suggerimenti di miglioramento del codice
- **Documentation**: Generazione automatica di documentazione

### Utilizzo Offline

Il sistema include modelli on-device per funzionalità base quando non c'è connessione:
- Code completion di base
- Syntax checking
- Simple code analysis

## Comandi di Sviluppo Specifici

### Debug su Dispositivi Fisici

```bash
# Verificare dispositivi connessi
flutter devices

# Debug su iOS (richiede Xcode)
flutter run -d ios

# Debug su Android
flutter run -d android

# Log dettagliati
flutter run --verbose
flutter logs
```

### Build di Produzione

```bash
# Android APK
flutter build apk --release

# Android App Bundle (per Play Store)
flutter build appbundle --release  

# iOS (richiede certificati)
flutter build ios --release

# Verificare dimensione bundle
flutter build apk --analyze-size
```

### Profilazione Performance

```bash
# Profiling performance
flutter run --profile

# Memory profiling  
flutter run --profile --trace-systrace

# Build size analysis
flutter build apk --analyze-size
```

## Workflow di Sviluppo

### 1. Setup Iniziale
```bash
git clone <repository-url>
cd warp-mobile-ai-ide
flutter pub get
```

### 2. Configurazione
- Creare file `.env` con API keys
- Configurare signing per iOS/Android se necessario
- Setup IDE con Flutter/Dart extensions

### 3. Sviluppo Feature
- Creare branch da `main`
- Implementare feature seguendo l'architettura esistente
- Scrivere test unitari e widget test
- Testare su dispositivi fisici

### 4. Quality Assurance
```bash
# Analisi codice
flutter analyze

# Formattazione
dart format . --set-exit-if-changed

# Test completi
flutter test
flutter test integration_test/
```

## Gestione Stato

### Provider Pattern (Stato Globale)
- **AppState**: Configurazione app e sessione utente
- **ProjectState**: Contesto progetto corrente
- **AIState**: Selezione modelli AI e cronologia
- **ThemeState**: Temi e personalizzazione UI

### Bloc Pattern (Stato Feature)
- **EditorBloc**: Editing file, highlighting, completion
- **TerminalBloc**: Cronologia comandi e sessioni
- **GitBloc**: Operazioni version control
- **PreviewBloc**: Stato anteprima app

## Testing

### Tipi di Test
```bash
# Test unitari (70%)
flutter test test/unit/

# Test di integrazione (20%) 
flutter test test/integration/

# Test widget (10%)
flutter test test/widget/

# Test end-to-end
flutter test integration_test/
```

### Mock e Testing AI
- Mock services per AI responses deterministic
- Test delle performance e latency
- Validazione output AI per sicurezza

## Distribuzione

### Preparazione Release

```bash
# Bump versione in pubspec.yaml
version: 1.0.1+2

# Build release
flutter build apk --release
flutter build ios --release

# Test release build
flutter install --release
```

### CI/CD

Il progetto è configurato per:
- **GitHub Actions**: Test automatizzati e build
- **CodeMagic**: Build ottimizzate per mobile
- **Firebase**: Analytics e crash reporting

### Distribuzione Store

- **iOS**: App Store Connect (TestFlight per beta)
- **Android**: Google Play Console (Internal testing per beta)

## Troubleshooting

### Problemi Comuni

**Build Errors**
```bash
# Pulire completamente
flutter clean
flutter pub get
cd ios && pod install  # Solo per iOS
```

**Problemi Dipendenze**
```bash
# Reset completo
flutter clean
rm pubspec.lock
flutter pub get
```

**Errori AI Integration**
- Verificare API keys in `.env`
- Controllare limiti di quota API
- Testare connettività di rete

**Problemi Performance**
- Usare `flutter run --profile` per profiling
- Verificare memory leaks nei Blocs
- Ottimizzare widget rebuilds

### Debug Avanzato

```bash
# Inspector Flutter
flutter inspector

# Debug network
flutter run --verbose

# Trace performance  
flutter run --trace-startup
```

## Funzionalità Principali

### 🖥️ Editor di Codice
- Syntax highlighting multi-linguaggio
- Code completion intelligente
- Error detection in tempo reale
- Multi-tab editing
- Theme personalizzabili

### 🤖 Integrazione AI
- Supporto multi-modello (OpenAI, Claude, Gemini)
- Code generation da linguaggio naturale  
- Debugging assistito da AI
- Code explanation e documentation
- Modelli on-device per offline

### 📱 Terminal Mobile
- Emulazione shell completa
- Command history e autocomplete
- Integrazione Git commands
- Output formattato con colori
- Process management

### 🔗 GitHub Integration
- Repository cloning e management
- Branch operations (create, switch, merge)
- Commit e push operations
- Pull request creation e review
- Visual diff viewer

### 📲 Preview In-App
- Flutter hot-reload integration
- Multi-platform preview (Web, Mobile)
- Debug console integration
- Performance profiling
- Testing framework integration

## Performance e Ottimizzazioni

### Mobile-Specific
- **Battery Optimization**: Gestione intelligente background processing
- **Memory Management**: Cleanup automatico e lazy loading
- **Network Efficiency**: Request batching e compression
- **Storage Optimization**: Caching strategico dei dati

### Metriche Target
- **Startup**: <3s app launch time
- **Memory**: <500MB RAM usage  
- **Battery**: 90%+ battery efficiency score
- **Reliability**: 99.9% crash-free sessions

## Roadmap e Sviluppo

Il progetto segue un roadmap dettagliato in 6 fasi:

1. **Foundation & MVP** (Settimane 1-8): Base IDE con AI
2. **Enhanced AI & Terminal** (Settimane 9-16): AI avanzata e terminal completo
3. **GitHub Integration** (Settimane 17-24): Version control completo
4. **Mobile Preview** (Settimane 25-32): Preview e testing in-app
5. **On-Device AI** (Settimane 33-40): Funzionalità offline
6. **Advanced Features** (Settimane 41-48): Funzionalità enterprise e polish

### Stato Attuale
Il progetto è attualmente nella **Fase 1**, con architettura base implementata e alcune funzionalità core in sviluppo.

## Contribuzione

### Workflow Contribuzione
1. Fork del repository
2. Creare feature branch
3. Implementare con test
4. Submit pull request con descrizione dettagliata
5. Code review e feedback
6. Merge dopo approvazione

### Standards di Codice
- Seguire Dart/Flutter style guide
- 95%+ test coverage per nuovo codice
- Documentazione per API pubbliche
- Performance testing per feature critiche

---

*Questo è un progetto ambizioso che mira a rivoluzionare lo sviluppo mobile portando la potenza degli IDE desktop direttamente sui dispositivi mobili con AI integrata.*