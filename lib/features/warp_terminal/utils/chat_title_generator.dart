import '../data/models/terminal_item.dart';

class ChatTitleGenerator {
  /// Genera un titolo significativo per una sessione di chat
  /// basato sul primo comando inviato
  static String generateTitle(List<TerminalItem> messages) {
    if (messages.isEmpty) return 'Chat Vuota';
    
    final firstCommand = messages.firstWhere(
      (item) => item.type == TerminalItemType.command,
      orElse: () => messages.first,
    );
    
    // Estrai solo il comando (senza il prompt)
    String commandText = firstCommand.content;
    if (commandText.contains('\$')) {
      final parts = commandText.split('\$');
      if (parts.length > 1) {
        commandText = parts.last.trim();
      }
    }
    
    // Genera un titolo significativo in base al contenuto del comando
    return _generateMeaningfulTitle(commandText);
  }
  
  static String _generateMeaningfulTitle(String command) {
    // Comando vuoto
    if (command.trim().isEmpty) return 'Nuova Conversazione';
    
    final lowerCmd = command.toLowerCase();
    
    // Comandi di avvio Flutter
    if (lowerCmd.contains('flutter run') || lowerCmd.contains('f run')) {
      return 'Avvio Applicazione Flutter';
    }
    
    // Comandi di creazione Flutter
    if (lowerCmd.contains('flutter create') || lowerCmd.startsWith('create') && lowerCmd.contains('flutter')) {
      return 'Creazione Nuovo Progetto Flutter';
    }
    
    // Comandi di test Flutter
    if (lowerCmd.contains('flutter test') || lowerCmd.contains('flutter drive')) {
      return 'Test Applicazione Flutter';
    }
    
    // Comandi build Flutter
    if (lowerCmd.contains('flutter build')) {
      String platform = '';
      if (lowerCmd.contains('ios')) platform = 'iOS';
      else if (lowerCmd.contains('android')) platform = 'Android';
      else if (lowerCmd.contains('web')) platform = 'Web';
      else if (lowerCmd.contains('windows')) platform = 'Windows';
      else if (lowerCmd.contains('macos')) platform = 'macOS';
      else if (lowerCmd.contains('linux')) platform = 'Linux';
      
      return platform.isNotEmpty 
          ? 'Build Flutter per \$platform' 
          : 'Build Applicazione Flutter';
    }
    
    // Comandi React/Next.js
    if (lowerCmd.contains('npm start') || lowerCmd.contains('yarn start') || 
        lowerCmd.contains('npm run dev') || lowerCmd.contains('yarn dev')) {
      return 'Avvio Applicazione React/Next.js';
    }
    
    // Comandi Python
    if (lowerCmd.startsWith('python') || lowerCmd.startsWith('python3')) {
      if (lowerCmd.contains('manage.py runserver')) {
        return 'Avvio Server Django';
      }
      if (lowerCmd.contains('flask run') || lowerCmd.contains('-m flask')) {
        return 'Avvio Server Flask';
      }
      // Avvio generico script Python
      return 'Esecuzione Script Python';
    }
    
    // Comandi Git
    if (lowerCmd.startsWith('git ')) {
      if (lowerCmd.contains('clone')) return 'Clonazione Repository Git';
      if (lowerCmd.contains('commit')) return 'Commit delle Modifiche';
      if (lowerCmd.contains('push')) return 'Push su Repository Remoto';
      if (lowerCmd.contains('pull')) return 'Pull da Repository Remoto';
      if (lowerCmd.contains('merge')) return 'Merge di Branch Git';
      if (lowerCmd.contains('branch')) return 'Gestione Branch Git';
      if (lowerCmd.contains('checkout')) return 'Cambio Branch Git';
      if (lowerCmd.contains('status')) return 'Verifica Stato Repository';
      return 'Operazioni Git';
    }
    
    // Comandi Docker
    if (lowerCmd.startsWith('docker ')) {
      if (lowerCmd.contains('build')) return 'Build Docker Image';
      if (lowerCmd.contains('run')) return 'Avvio Container Docker';
      if (lowerCmd.contains('compose')) return 'Docker Compose';
      return 'Operazioni Docker';
    }
    
    // Comandi di installazione
    if (lowerCmd.contains('npm install') || lowerCmd.contains('yarn add') || 
        lowerCmd.contains('pip install') || lowerCmd.contains('pub get') || 
        lowerCmd.contains('flutter pub get')) {
      return 'Installazione Dipendenze';
    }
    
    // Gestione files
    if (lowerCmd.startsWith('ls') || lowerCmd.startsWith('dir') || 
        lowerCmd.startsWith('cd') || lowerCmd.startsWith('mkdir') || 
        lowerCmd.startsWith('mv') || lowerCmd.startsWith('cp')) {
      return 'Gestione File e Directory';
    }
    
    // Se è una domanda
    if (lowerCmd.contains('?') || lowerCmd.startsWith('come') || 
        lowerCmd.startsWith('cosa') || lowerCmd.startsWith('quando') || 
        lowerCmd.startsWith('perché') || lowerCmd.startsWith('dove')) {
      // Tronca la domanda se troppo lunga
      if (command.length > 40) {
        return '\${command.substring(0, 40)}...';
      }
      return command; // Restituisci la domanda completa
    }
    
    // Fallback per altri comandi
    if (command.length > 40) {
      return '\${command.substring(0, 40)}...';
    }
    return command;
  }
}