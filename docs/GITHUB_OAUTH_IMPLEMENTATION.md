# GitHub OAuth Implementation - Warp Mobile AI IDE

## Panoramica

Implementazione completa del sistema di autenticazione GitHub OAuth 2.0 per l'app mobile Warp AI IDE. Gli utenti possono ora connettersi direttamente con il loro account GitHub senza dover inserire manualmente un Personal Access Token.

## Architettura Implementata

### 1. GitHub Service (`lib/core/github/github_service.dart`)

**Funzionalità principali:**
- Gestione OAuth flow completo senza client secret (Public OAuth App)
- Generazione sicura del parametro `state` per prevenire attacchi CSRF
- Exchange del codice di autorizzazione per access token
- Archiviazione sicura di credenziali tramite FlutterSecureStorage
- Gestione dei dati utente e repository GitHub
- Fallback al metodo tradizionale con Personal Access Token

**Metodi chiave:**
- `startOAuthFlow()`: Avvia il flusso OAuth aprendo GitHub nel browser
- `handleAuthCallback()`: Gestisce la callback OAuth e scambia il codice per il token
- `fetchUserRepositories()`: Carica le repository dell'utente autenticato
- `authenticateWithToken()`: Metodo alternativo per token manuali

### 2. Deep Link Handler (`lib/core/github/deep_link_handler.dart`)

**Funzionalità:**
- Gestione delle deep link per le callback OAuth
- Comunicazione bidirezionale con il layer nativo iOS/Android
- Parsing e validazione degli URL di callback
- Routing automatico dei dati OAuth al GitHub Service

**Schema URL:** `warp-mobile://oauth/github`

### 3. UI Integration (`lib/features/warp_terminal/presentation/pages/warp_terminal_page.dart`)

**Miglioramenti UI:**
- Pulsante "Connetti GitHub" con indicatore di caricamento
- Lista interattiva delle repository nel drawer laterale
- Selezione repository con feedback visivo
- Menu a tendina per ricarica/disconnessione
- Visualizzazione del profilo utente con avatar
- Badge con conteggio repository caricate
- Indicatori di stato per repository private/pubbliche
- Colori specifici per linguaggi di programmazione

### 4. Configurazione iOS (`ios/Runner/`)

**AppDelegate.swift:**
- Gestione deep link tramite URL scheme
- Method channel per comunicazione Flutter-iOS
- Supporto per app launch tramite deep link

**Info.plist:**
- Registrazione URL scheme `warp-mobile`
- Configurazione per gestione OAuth callback

## Flusso OAuth Implementato

```
1. User tap "Connetti GitHub"
   ↓
2. App genera state sicuro e costruisce URL OAuth
   ↓  
3. Apre browser con GitHub authorization
   ↓
4. User autorizza l'app su GitHub
   ↓
5. GitHub redirect a warp-mobile://oauth/github?code=xxx&state=xxx
   ↓
6. iOS gestisce deep link e comunica con Flutter
   ↓
7. Flutter verifica state e scambia code per access token
   ↓
8. Archivia token e carica dati utente/repository
   ↓
9. Aggiorna UI con repository disponibili
```

## Configurazione GitHub OAuth App

**Client ID:** `Ov23liWJNYRzL4xTqhpn`
**Redirect URI:** `warp-mobile://oauth/github`
**Scopes richiesti:**
- `repo`: Accesso completo alle repository
- `user:email`: Lettura email utente
- `read:user`: Lettura informazioni profilo utente

## Sicurezza Implementata

### 1. **CSRF Protection**
- Generazione random del parametro `state` a 32 caratteri
- Verifica `state` nella callback prima di processare il `code`
- Pulizia automatica dello `state` dopo l'uso

### 2. **Secure Storage**
- Utilizzo di FlutterSecureStorage per credenziali
- Archiviazione separata di token, user data, e state temporaneo
- Pulizia automatica dei dati temporanei

### 3. **Public OAuth App**
- Nessun client secret necessario (più sicuro per app mobile)
- Utilizzo del GitHub Device Flow quando applicabile
- Validazione server-side tramite GitHub API

## Funzionalità UI

### Repository Management
- **Selezione Repository**: Tap per selezionare/deselezionare
- **Indicatori Visivi**: 
  - 🔒 Repository private
  - 🌍 Repository pubbliche  
  - ⭐ Numero stelle
  - 🎯 Linguaggio principale con colore distintivo
- **Badge Contatore**: Mostra numero totale repository
- **Menu Gestione**: Ricarica repository, disconnetti account

### User Profile Display  
- **Avatar Utente**: Immagine profilo GitHub o iniziale nome
- **Informazioni**: Nome reale e username GitHub
- **Stato Connessione**: Indicatore visivo verde

### Loading States
- **Connessione**: Spinner durante l'OAuth flow
- **Caricamento Repository**: Indicatore durante fetch dati
- **Stati di Errore**: Messaggi esplicativi per fallimenti

## Testing e Debug

### Log Messages
L'implementazione include logging estensivo per debug:
- `🚀 Launching GitHub OAuth URL`
- `🔗 Received GitHub OAuth callback`
- `✅ GitHub OAuth successful for user`
- `❌ OAuth state mismatch - possible CSRF attack`

### Error Handling
- Gestione errori di rete durante OAuth flow
- Validazione parametri URL callback
- Recovery automatico da stati inconsistenti
- Messaggi utente user-friendly

## Compatibilità

- **iOS**: Completa con deep link nativi
- **Android**: Architettura pronta (necessaria configurazione AndroidManifest.xml)
- **Fallback**: Mantiene supporto per Personal Access Token

## Prossimi Sviluppi Suggeriti

1. **Configurazione Android**: Implementare deep link per Android
2. **Repository Caching**: Cache locale per ridurre API calls
3. **Refresh Token**: Gestione refresh automatico token scaduti  
4. **Repository Search**: Ricerca e filtro repository nell'UI
5. **Organization Support**: Supporto repository di organizzazioni
6. **Webhooks**: Integrazione notifiche GitHub in tempo reale

## Dependencies Aggiunte

```yaml
dependencies:
  crypto: ^3.0.3  # Per generazione sicura del state parameter
```

## Conclusioni

L'implementazione OAuth fornisce un'esperienza utente fluida e sicura per la connessione con GitHub, sostituendo efficacemente il precedente approccio basato su Personal Access Token. La architettura modulare permette facile estensione per altri provider OAuth in futuro.