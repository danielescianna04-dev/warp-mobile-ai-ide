# Settings Feature

Questa feature implementa la pagina delle impostazioni completa dell'applicazione Warp AI IDE.

## Struttura

```
lib/features/settings/
├── data/
│   └── models/
│       └── user_settings.dart     # Modelli dati per le impostazioni
├── presentation/
│   └── pages/
│       └── settings_page.dart     # Pagina principale delle impostazioni
└── README.md                      # Questo file
```

## Funzionalità

### 🔧 Sezioni delle Impostazioni

1. **Profilo Utente**
   - Avatar utente (con possibilità di modifica)
   - Nome, email, bio, azienda, posizione
   - Interfaccia moderna con form validati

2. **Preferenze App**
   - Selezione tema (Scuro, Chiaro, Sistema)
   - Selezione lingua (🇮🇹 Italiano, 🇺🇸 English, 🇪🇸 Español, 🇫🇷 Français)
   - Feedback aptico on/off
   - Animazioni on/off
   - Blur sidebar on/off
   - Slider per dimensione font (10-24px)

3. **Impostazioni AI**
   - Selezione modello AI predefinito
   - Slider per temperatura AI (0.0-1.0) con descrizioni:
     - 0.0-0.3: "Preciso"
     - 0.4-0.7: "Equilibrato"
     - 0.8-1.0: "Creativo"
   - Risposta streaming on/off
   - Memoria contesto on/off

4. **GitHub Integration**
   - Stato connessione GitHub
   - Connetti/disconnetti account
   - Auto-sync repository
   - Notifiche GitHub

5. **Sicurezza**
   - Autenticazione biometrica (Face ID/Touch ID)
   - Crittografia dati
   - Timeout sessione
   - Permessi screenshot

6. **Informazioni**
   - Privacy Policy
   - Termini di servizio
   - Supporto
   - Versione app

### 💾 Persistenza

- Utilizza **flutter_secure_storage** per salvare le impostazioni in modo sicuro
- Caricamento automatico all'avvio
- Salvataggio con feedback all'utente
- Gestione errori robusta

### 🎨 Design

- **Interfaccia moderna** con animazioni fluide
- **Sezioni organizzate** con icone e colori coerenti
- **Material Design** con elementi personalizzati
- **Transizioni animate** per una UX premium
- **Tema coerente** con il resto dell'applicazione

### 🚀 Navigazione

La pagina delle impostazioni è accessibile cliccando sulla **foto profilo** nella sidebar dell'applicazione principale.

## Utilizzo

### Da codice

```dart
// Navigare alla pagina delle impostazioni
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
);

// Passare impostazioni iniziali (opzionale)
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => SettingsPage(
      initialSettings: myUserSettings,
    ),
  ),
);
```

### Lavorare con le impostazioni

```dart
// Caricare impostazioni salvate
final settingsJson = await secureStorage.read(key: 'user_settings');
final settings = settingsJson != null 
    ? UserSettings.fromJson(jsonDecode(settingsJson))
    : UserSettings.defaultSettings();

// Modificare impostazioni
final updatedSettings = settings.copyWith(
  preferences: settings.preferences.copyWith(
    theme: 'dark',
    enableHapticFeedback: true,
  ),
);

// Salvare impostazioni
await secureStorage.write(
  key: 'user_settings', 
  value: jsonEncode(updatedSettings.toJson())
);
```

## Integrazione

La feature è già integrata con:

- **warp_terminal_page.dart**: Navigazione dalla foto profilo
- **app_colors.dart**: Utilizza i colori dell'applicazione
- **flutter_secure_storage**: Per la persistenza sicura

## Estensioni Future

- [ ] Backup e sincronizzazione cloud delle impostazioni
- [ ] Temi personalizzabili avanzati
- [ ] Integrazione con provider di autenticazione esterni
- [ ] Impostazioni avanzate per sviluppatori
- [ ] Esportazione/importazione configurazioni
- [ ] Notifiche push personalizzabili

## Dipendenze

- `flutter/material.dart`
- `flutter/services.dart`
- `flutter_secure_storage`
- Colori e costanti dell'app esistenti