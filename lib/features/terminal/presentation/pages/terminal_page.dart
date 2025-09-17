import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TerminalLine> _terminalLines = [];
  String _currentPath = '~/projects/warp-mobile-ai-ide';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _terminalLines.addAll([
      TerminalLine(
        text: '🚀 Welcome to Warp Mobile AI IDE Terminal',
        type: TerminalLineType.info,
      ),
      TerminalLine(
        text: 'Mobile-first development with AI assistance',
        type: TerminalLineType.normal,
      ),
      TerminalLine(
        text: 'Type "help" to see available commands',
        type: TerminalLineType.hint,
      ),
      TerminalLine(
        text: '',
        type: TerminalLineType.normal,
      ),
    ]);
    setState(() {});
  }

  void _executeCommand(String command) {
    if (command.trim().isEmpty) return;

    // Add command to terminal
    _terminalLines.add(TerminalLine(
      text: '${_getPrompt()} $command',
      type: TerminalLineType.command,
    ));

    // Process command
    _processCommand(command.trim());

    // Clear input and scroll to bottom
    _commandController.clear();
    _scrollToBottom();
  }

  void _processCommand(String command) {
    final parts = command.split(' ');
    final cmd = parts[0];

    switch (cmd.toLowerCase()) {
      case 'help':
        _addHelpMessage();
        break;
      case 'ls':
      case 'dir':
        _listDirectory();
        break;
      case 'pwd':
        _showCurrentDirectory();
        break;
      case 'cd':
        if (parts.length > 1) {
          _changeDirectory(parts[1]);
        } else {
          _addOutput('Usage: cd <directory>', TerminalLineType.error);
        }
        break;
      case 'flutter':
        _handleFlutterCommand(parts.skip(1).toList());
        break;
      case 'git':
        _handleGitCommand(parts.skip(1).toList());
        break;
      case 'clear':
        _clearTerminal();
        return;
      case 'ai':
      case 'ask':
        _handleAICommand(parts.skip(1).join(' '));
        break;
      default:
        _addOutput('Command not found: $cmd', TerminalLineType.error);
        _addOutput('Type "help" for available commands', TerminalLineType.hint);
    }

    _addEmptyLine();
  }

  void _addHelpMessage() {
    final commands = [
      'Available commands:',
      '',
      '📁 File Operations:',
      '  ls, dir          - List directory contents',
      '  pwd              - Show current directory',
      '  cd <dir>         - Change directory',
      '',
      '🚀 Flutter Commands:',
      '  flutter run      - Run the Flutter app',
      '  flutter build    - Build the app',
      '  flutter test     - Run tests',
      '  flutter pub get  - Get dependencies',
      '',
      '📦 Git Commands:',
      '  git status       - Show git status',
      '  git add .        - Stage all changes',
      '  git commit       - Commit changes',
      '  git push         - Push to remote',
      '',
      '🤖 AI Commands:',
      '  ai <question>    - Ask AI assistant',
      '  ask <question>   - Ask AI assistant',
      '',
      '⚙️ Utilities:',
      '  clear            - Clear terminal',
      '  help             - Show this help',
    ];

    for (final line in commands) {
      _addOutput(line, line.startsWith('📁') || line.startsWith('🚀') || 
                     line.startsWith('📦') || line.startsWith('🤖') || 
                     line.startsWith('⚙️') 
                     ? TerminalLineType.info 
                     : TerminalLineType.normal);
    }
  }

  void _listDirectory() {
    final files = [
      'lib/',
      'android/',
      'ios/',
      'web/',
      'test/',
      'pubspec.yaml',
      'README.md',
      '.gitignore',
      'analysis_options.yaml',
    ];

    for (final file in files) {
      final isDirectory = file.endsWith('/');
      _addOutput(
        file,
        isDirectory ? TerminalLineType.directory : TerminalLineType.file,
      );
    }
  }

  void _showCurrentDirectory() {
    _addOutput(_currentPath, TerminalLineType.info);
  }

  void _changeDirectory(String dir) {
    if (dir == '..') {
      final parts = _currentPath.split('/');
      if (parts.length > 1) {
        parts.removeLast();
        _currentPath = parts.join('/');
        if (_currentPath.isEmpty) _currentPath = '/';
      }
    } else if (dir.startsWith('/')) {
      _currentPath = dir;
    } else {
      _currentPath = '$_currentPath/$dir'.replaceAll('//', '/');
    }
    _addOutput('Changed to: $_currentPath', TerminalLineType.success);
  }

  void _handleFlutterCommand(List<String> args) {
    if (args.isEmpty) {
      _addOutput('Flutter 3.16.0 • Dart 3.2.0', TerminalLineType.info);
      return;
    }

    switch (args[0]) {
      case 'run':
        _simulateFlutterRun();
        break;
      case 'build':
        _addOutput('🔨 Building Flutter app...', TerminalLineType.info);
        _addOutput('✅ Build completed successfully!', TerminalLineType.success);
        break;
      case 'test':
        _addOutput('🧪 Running tests...', TerminalLineType.info);
        _addOutput('All tests passed! ✅', TerminalLineType.success);
        break;
      case 'pub':
        if (args.length > 1 && args[1] == 'get') {
          _addOutput('📦 Getting dependencies...', TerminalLineType.info);
          _addOutput('✅ Dependencies resolved!', TerminalLineType.success);
        }
        break;
      default:
        _addOutput('Unknown Flutter command: ${args[0]}', TerminalLineType.error);
    }
  }

  void _simulateFlutterRun() {
    _addOutput('🚀 Starting Flutter app...', TerminalLineType.info);
    _addOutput('Launching on mobile device...', TerminalLineType.normal);
    _addOutput('Hot reload enabled 🔥', TerminalLineType.success);
    _addOutput('App running on http://localhost:3000', TerminalLineType.info);
  }

  void _handleGitCommand(List<String> args) {
    if (args.isEmpty) {
      _addOutput('Git version 2.40.0', TerminalLineType.info);
      return;
    }

    switch (args[0]) {
      case 'status':
        _showGitStatus();
        break;
      case 'add':
        _addOutput('✅ Changes staged', TerminalLineType.success);
        break;
      case 'commit':
        _addOutput('📝 Changes committed', TerminalLineType.success);
        break;
      case 'push':
        _addOutput('📤 Pushed to remote repository', TerminalLineType.success);
        break;
      default:
        _addOutput('Git command: ${args[0]} (simulated)', TerminalLineType.info);
    }
  }

  void _showGitStatus() {
    final statusLines = [
      'On branch main',
      'Your branch is up to date with \'origin/main\'.',
      '',
      'Changes not staged for commit:',
      '  modified:   lib/main.dart',
      '  modified:   pubspec.yaml',
      '',
      'Untracked files:',
      '  lib/features/editor/',
      '  lib/features/terminal/',
      '',
      'use "git add" to stage changes',
    ];

    for (final line in statusLines) {
      TerminalLineType type = TerminalLineType.normal;
      if (line.contains('modified:')) type = TerminalLineType.warning;
      if (line.contains('Untracked')) type = TerminalLineType.info;
      _addOutput(line, type);
    }
  }

  void _handleAICommand(String question) {
    if (question.isEmpty) {
      _addOutput('Usage: ai <your question>', TerminalLineType.error);
      return;
    }

    _addOutput('🤖 AI Assistant:', TerminalLineType.info);
    
    // Simulate AI response based on question
    String response = _generateAIResponse(question);
    _addOutput(response, TerminalLineType.success);
  }

  String _generateAIResponse(String question) {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('flutter') || lowerQuestion.contains('dart')) {
      return 'Flutter is a great choice for mobile development! It offers hot reload, cross-platform support, and a rich widget ecosystem. Would you like help with a specific Flutter concept?';
    }
    
    if (lowerQuestion.contains('git')) {
      return 'Git is essential for version control. Key commands: git add (stage), git commit (save), git push (upload). Need help with a specific Git workflow?';
    }
    
    if (lowerQuestion.contains('debug') || lowerQuestion.contains('error')) {
      return 'For debugging: 1) Check console logs, 2) Use breakpoints, 3) Verify imports, 4) Check variable types. Share the error message for specific help!';
    }
    
    return 'I\'m here to help with mobile development! Ask me about Flutter, Dart, Git, debugging, or any coding questions. Full AI integration coming soon! 🚀';
  }

  void _clearTerminal() {
    setState(() {
      _terminalLines.clear();
    });
  }

  void _addOutput(String text, TerminalLineType type) {
    _terminalLines.add(TerminalLine(text: text, type: type));
    setState(() {});
  }

  void _addEmptyLine() {
    _terminalLines.add(TerminalLine(text: '', type: TerminalLineType.normal));
    setState(() {});
  }

  String _getPrompt() {
    final pathParts = _currentPath.split('/');
    final shortPath = pathParts.length > 2 
        ? '.../${pathParts.sublist(pathParts.length - 2).join('/')}'
        : _currentPath;
    return 'warp:$shortPath\$';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.terminalBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.terminalCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.terminal,
                    size: 16,
                    color: AppColors.terminalCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terminal',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.terminalCyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearTerminal,
            icon: Icon(Icons.clear_all, color: AppColors.textSecondary),
            tooltip: 'Clear',
          ),
          IconButton(
            onPressed: () {
              // TODO: Terminal settings
            },
            icon: Icon(Icons.settings, color: AppColors.textSecondary),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _terminalLines.length,
              itemBuilder: (context, index) {
                final line = _terminalLines[index];
                return _buildTerminalLine(line);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Text(
                  _getPrompt(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.terminalCyan,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.terminalText,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    onSubmitted: _executeCommand,
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalLine(TerminalLine line) {
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;

    switch (line.type) {
      case TerminalLineType.command:
        textColor = AppColors.terminalText;
        fontWeight = FontWeight.bold;
        break;
      case TerminalLineType.success:
        textColor = AppColors.terminalGreen;
        break;
      case TerminalLineType.error:
        textColor = AppColors.terminalRed;
        break;
      case TerminalLineType.warning:
        textColor = AppColors.terminalYellow;
        break;
      case TerminalLineType.info:
        textColor = AppColors.terminalBlue;
        break;
      case TerminalLineType.directory:
        textColor = AppColors.terminalBlue;
        fontWeight = FontWeight.bold;
        break;
      case TerminalLineType.file:
        textColor = AppColors.terminalText;
        break;
      case TerminalLineType.hint:
        textColor = AppColors.textTertiary;
        break;
      default:
        textColor = AppColors.terminalText;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        line.text,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontFamily: 'monospace',
          fontWeight: fontWeight,
          height: 1.2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class TerminalLine {
  final String text;
  final TerminalLineType type;

  TerminalLine({
    required this.text,
    required this.type,
  });
}

enum TerminalLineType {
  normal,
  command,
  success,
  error,
  warning,
  info,
  directory,
  file,
  hint,
}