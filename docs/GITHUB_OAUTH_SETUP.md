# GitHub OAuth App Setup Guide

## Problema Attuale

L'app sta cercando di usare un Client ID di esempio (`Ov23liWJNYRzL4xTqhpn`) che non esiste realmente, causando l'errore 404 su GitHub.

## Soluzione: Crea la tua GitHub OAuth App

### Step 1: Crea l'OAuth App su GitHub

1. **Accedi a GitHub** e vai su: https://github.com/settings/developers
2. **Clicca** su **"New OAuth App"**
3. **Compila i campi**:
   - **Application name**: `Warp Mobile AI IDE`
   - **Homepage URL**: `https://github.com/tuousername/warp-mobile-ai-ide` (o il tuo repository)
   - **Application description**: `Mobile AI IDE with GitHub integration for Flutter development`
   - **Authorization callback URL**: `warp-mobile://oauth/github`

4. **Clicca** "Register application"
5. **Copia il Client ID** che GitHub genera (sarà simile a `Ov23li1234567890abcdef`)

### Step 2: Aggiorna il Codice

Sostituisci nel file `lib/core/github/github_service.dart`:

```dart
// Da:
static const String _clientId = 'YOUR_GITHUB_CLIENT_ID_HERE';

// A:
static const String _clientId = 'IL_TUO_CLIENT_ID_REALE';
```

### Step 3: Testa l'OAuth Flow

1. **Ricompila l'app** con `flutter run`
2. **Clicca** "Connetti GitHub"
3. **Dovrebbe aprirsi** Safari con la pagina di autorizzazione GitHub corretta
4. **Autorizza l'app** - GitHub dovrebbe reindirizzare a `warp-mobile://oauth/github?code=...`

## Alternativa Temporanea: Personal Access Token

Mentre configuri l'OAuth App, puoi usare il metodo Personal Access Token:

### Come Creare un Personal Access Token

1. **Vai su**: https://github.com/settings/tokens
2. **Clicca** "Generate new token (classic)"
3. **Seleziona gli scope**:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `user:email` (Access user email addresses)  
   - ✅ `read:user` (Read user profile data)
4. **Genera il token** e copialo
5. **Nell'app**, clicca "Connetti GitHub" → "Usa Personal Access Token"
6. **Incolla il token** e connettiti

## Risoluzione Problemi Deep Link

Se anche dopo aver configurato l'OAuth App correttamente il deep link non funziona:

### iOS Simulator Issues
Il simulatore iOS a volte non gestisce bene i custom URL scheme. Prova su:
- **Dispositivo fisico** iOS 
- **Approccio manuale** con il pulsante "Test OAuth (Debug)"

### Verifica Configurazione iOS
Controlla che in `ios/Runner/Info.plist` sia presente:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GitHub OAuth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>warp-mobile</string>
        </array>
    </dict>
</array>
```

## Test Manuale Deep Link

Se l'OAuth non funziona automaticamente:

1. **Avvia l'app** 
2. **Clicca** "Test OAuth (Debug)"
3. **In un browser**, vai manualmente all'URL OAuth:
   ```
   https://github.com/login/oauth/authorize?client_id=IL_TUO_CLIENT_ID&redirect_uri=warp-mobile%3A//oauth/github&scope=repo,user:email,read:user&state=test123
   ```
4. **Autorizza l'app** 
5. **Copia l'URL finale** dalla barra del browser (sarà `warp-mobile://oauth/github?code=...`)
6. **Incollalo** nel dialog "Test OAuth"

## Next Steps

Una volta configurata l'OAuth App:

1. ✅ L'utente può fare login con un click
2. ✅ Nessun token manuale da inserire
3. ✅ Accesso sicuro alle repository
4. ✅ Refresh automatico delle credenziali

Il flusso OAuth è già implementato e funzionale - serve solo la configurazione GitHub corretta!