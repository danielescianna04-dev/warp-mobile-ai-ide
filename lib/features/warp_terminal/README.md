# Warp Terminal

Una implementazione moderna e modulare del terminale per l'IDE mobile Warp AI.

## 🚀 Features

- **Architettura Modulare**: Separazione chiara tra logica, UI e modelli
- **Provider Pattern**: Gestione dello stato reattivo con Provider
- **Syntax Highlighting**: Evidenziazione della sintassi per comandi terminal
- **Chat GitHub Integration**: Supporto per associare chat alle repository GitHub
- **Design System Coerente**: UI uniforme con il resto dell'applicazione
- **Comandi Simulati**: Supporto per comandi comuni (ls, pwd, git, flutter, etc.)

## 📁 Struttura del Progetto

```
lib/features/warp_terminal/
├── data/
│   └── models/
│       └── terminal_item.dart          # Modello per gli elementi del terminal
├── presentation/
│   ├── pages/
│   │   ├── warp_terminal_page.dart     # Pagina completa del terminal (esistente)
│   │   └── simple_terminal_page.dart   # Versione semplificata con provider
│   ├── providers/
│   │   └── terminal_provider.dart      # Provider per gestione stato terminal
│   └── widgets/
│       └── terminal/
│           ├── terminal_input.dart     # Widget input del terminal
│           ├── terminal_output.dart    # Widget output del terminal
│           └── welcome_view.dart       # Vista di benvenuto
├── test_terminal_page.dart             # Pagina di test con esempi
└── README.md                           # Questo file
```

## 🎯 Architettura

### Modelli
- **TerminalItem**: Rappresenta un elemento del terminal (comando, output, errore, sistema)
- **TerminalItemType**: Enum per i tipi di elementi del terminal

### Provider
- **TerminalProvider**: Gestisce lo stato del terminal con ChangeNotifier
  - Cronologia dei comandi e output
  - Stato di loading
  - Gestione comandi simulati

### Widgets
- **TerminalInput**: Campo di input per i comandi con supporto multilinea
- **TerminalOutput**: Lista scrollabile dell'output del terminal con syntax highlighting
- **WelcomeView**: Vista di benvenuto con design moderno

## 📱 Utilizzo

### Implementazione Base

```dart
import 'package:provider/provider.dart';
import 'package:warp_mobile_ai_ide/features/warp_terminal/presentation/pages/simple_terminal_page.dart';

// Navigazione al terminal
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const SimpleTerminalPage(),
  ),
);
```

### Integrazione con Provider

```dart
ChangeNotifierProvider(
  create: (_) => TerminalProvider(),
  child: Consumer<TerminalProvider>(
    builder: (context, provider, _) {
      return TerminalOutput(items: provider.items);
    },
  ),
)
```

## 🔧 Comandi Supportati

Il TerminalProvider simula i seguenti comandi:

| Comando | Descrizione | Output |
|---------|-------------|---------|
| `ls` | Lista file e directory | Lista dei file del progetto |
| `pwd` | Directory corrente | Percorso assoluto |
| `git status` | Stato repository Git | Stato dei file modificati |
| `git log` | Cronologia commit | Lista dei commit recenti |
| `flutter --version` | Versione Flutter | Info versione SDK |
| `flutter pub get` | Dipendenze | Processo di download |
| `flutter clean` | Pulizia build | Cancellazione directory build |
| `cd <dir>` | Cambia directory | Conferma cambio |
| `clear` | Pulisci terminal | Pulizia completa |
| `help` | Mostra aiuto | Lista comandi disponibili |

## 🎨 Design System

Il terminal utilizza il design system dell'app con:

- **AppColors**: Palette colori coerente
- **Typography**: Font monospace per terminal
- **Gradients**: Effetti visivi moderni
- **Shadows**: Profondità e elevazione
- **Animations**: Transizioni fluide

### Colori Principali

```dart
// Comandi
textColor = AppColors.purpleMedium;

// Output normale  
textColor = AppColors.textPrimary;

// Errori
textColor = AppColors.error;

// Sistema
textColor = AppColors.textTertiary;
```

## 🔗 Integrazione GitHub

Il sistema supporta l'associazione di chat alle repository GitHub:

```dart
ChatSession(
  id: 'chat-001',
  title: 'Setup Flutter App',
  repositoryId: 'repo-123',
  repositoryName: 'my-flutter-app', // Visualizzato nella sidebar
  // ...
)
```

Le chat associate mostrano:
- Icona GitHub nella sidebar
- Nome repository sotto il titolo
- Indicatore visivo di repository collegata

## 🧪 Test

Per testare le funzionalità:

```dart
import 'package:warp_mobile_ai_ide/features/warp_terminal/test_terminal_page.dart';

// Avvia la pagina di test
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const TestTerminalPage()),
);
```

La pagina di test include:
- Accesso diretto al terminal
- Esempio di chat GitHub
- Lista dei comandi disponibili

## 🚀 Prossimi Sviluppi

- [ ] Integrazione con terminale reale del sistema
- [ ] Supporto per tab multipli
- [ ] Autocompletamento comandi
- [ ] Cronologia persistente
- [ ] Temi personalizzabili
- [ ] Plugin per comandi custom
- [ ] Integrazione con AI per suggerimenti

## 🔧 Dipendenze

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  
# Dipendenze già presenti nel progetto principale
```

---

*Implementazione in linea con l'architettura modulare dell'app Warp AI Mobile IDE*