import 'package:flutter/material.dart';
import '../../data/models/terminal_item.dart';

class TerminalProvider extends ChangeNotifier {
  final List<TerminalItem> _items = [];
  String _currentCommand = '';
  bool _isLoading = false;

  List<TerminalItem> get items => _items;
  String get currentCommand => _currentCommand;
  bool get isLoading => _isLoading;
  bool get hasOutput => _items.isNotEmpty;

  void updateCommand(String command) {
    _currentCommand = command;
    notifyListeners();
  }

  void clearCommand() {
    _currentCommand = '';
    notifyListeners();
  }

  void executeCommand(String command) {
    if (command.trim().isEmpty) return;

    // Aggiungi il comando alla cronologia
    _items.add(TerminalItem(
      content: '\$ $command',
      type: TerminalItemType.command,
      timestamp: DateTime.now(),
    ));

    // Simula l'elaborazione del comando
    _isLoading = true;
    notifyListeners();

    // Simula una risposta ritardata
    Future.delayed(const Duration(milliseconds: 800), () {
      _handleCommandResponse(command);
    });

    _currentCommand = '';
  }

  void _handleCommandResponse(String command) {
    _isLoading = false;
    
    // Gestisci comandi comuni
    if (command.toLowerCase().startsWith('ls')) {
      _addOutputItem('''src/
lib/
pubspec.yaml
README.md
.gitignore
android/
ios/
test/''');
    } else if (command.toLowerCase().startsWith('pwd')) {
      _addOutputItem('/Users/getmad/Projects/warp-mobile-ai-ide');
    } else if (command.toLowerCase().startsWith('flutter')) {
      if (command.contains('--version')) {
        _addOutputItem('''Flutter 3.24.3 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 2663184aa7 (6 weeks ago) • 2024-09-11 16:27:48 -0500
Engine • revision 36335019a8
Tools • Dart 3.5.3 • DevTools 2.37.3''');
      } else if (command.contains('pub get')) {
        _addOutputItem('Running "flutter pub get" in warp-mobile-ai-ide...');
        Future.delayed(const Duration(milliseconds: 600), () {
          _addOutputItem('Resolving dependencies... \nGot dependencies!');
        });
        return;
      } else if (command.contains('clean')) {
        _addOutputItem('Deleting build/ directory...\nDeleted build directory.');
      } else {
        _addOutputItem('Flutter SDK è configurato correttamente.');
      }
    } else if (command.toLowerCase().startsWith('git')) {
      if (command.contains('status')) {
        _addOutputItem('''On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   lib/features/chat/models/chat_session.dart
        modified:   lib/features/sidebar/sidebar_view.dart

no changes added to commit (use "git add ." or "git commit -a")''');
      } else if (command.contains('log')) {
        _addOutputItem('''commit a1b2c3d (HEAD -> main, origin/main)
Author: Developer <dev@warp.com>
Date:   Mon Oct 28 14:30:00 2024 +0100

    feat: implementata visualizzazione repository GitHub nelle chat

commit e4f5g6h
Author: Developer <dev@warp.com>
Date:   Mon Oct 28 13:15:00 2024 +0100

    fix: risolti problemi di sintassi nella sidebar GitHub''');
      } else {
        _addOutputItem('Git repository inizializzato.');
      }
    } else if (command.toLowerCase().startsWith('cd')) {
      _addOutputItem('Directory cambiata.');
    } else if (command.toLowerCase().startsWith('clear')) {
      _items.clear();
      notifyListeners();
      return;
    } else if (command.toLowerCase().startsWith('help')) {
      _addOutputItem('''Comandi disponibili:
  ls              - Elenca file e directory
  pwd             - Mostra directory corrente
  cd <directory>  - Cambia directory
  clear           - Pulisce il terminale
  git <command>   - Comandi Git
  flutter <cmd>   - Comandi Flutter
  help            - Mostra questo aiuto''');
    } else {
      // Comando non riconosciuto
      _addErrorItem('Comando non riconosciuto: $command');
    }
    
    notifyListeners();
  }

  void _addOutputItem(String content) {
    _items.add(TerminalItem(
      content: content,
      type: TerminalItemType.output,
      timestamp: DateTime.now(),
    ));
  }

  void _addErrorItem(String content) {
    _items.add(TerminalItem(
      content: content,
      type: TerminalItemType.error,
      timestamp: DateTime.now(),
    ));
  }

  void _addSystemItem(String content) {
    _items.add(TerminalItem(
      content: content,
      type: TerminalItemType.system,
      timestamp: DateTime.now(),
    ));
  }

  void clearTerminal() {
    _items.clear();
    _currentCommand = '';
    _isLoading = false;
    notifyListeners();
  }
}