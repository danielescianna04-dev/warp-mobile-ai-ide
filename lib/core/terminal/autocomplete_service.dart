import 'dart:io';
import 'package:path/path.dart' as path;

class AutocompleteService {
  static final AutocompleteService _instance = AutocompleteService._internal();
  factory AutocompleteService() => _instance;
  AutocompleteService._internal();

  // Common commands with their descriptions
  final Map<String, String> _commonCommands = {
    // Git commands
    'git': 'Git version control',
    'git add': 'Add file contents to the index',
    'git commit': 'Record changes to the repository',
    'git push': 'Update remote refs along with associated objects',
    'git pull': 'Fetch from and integrate with another repository',
    'git status': 'Show the working tree status',
    'git log': 'Show commit logs',
    'git branch': 'List, create, or delete branches',
    'git checkout': 'Switch branches or restore working tree files',
    'git merge': 'Join two or more development histories together',
    'git clone': 'Clone a repository into a new directory',
    'git diff': 'Show changes between commits, commit and working tree, etc',
    
    // NPM commands
    'npm': 'Node Package Manager',
    'npm install': 'Install a package',
    'npm run': 'Run arbitrary package scripts',
    'npm start': 'Start a package',
    'npm test': 'Test a package',
    'npm build': 'Build a package',
    'npm run dev': 'Run development server',
    'npm run build': 'Build for production',
    'npm run test': 'Run test suite',
    'npm init': 'Initialize a new package',
    'npm update': 'Update packages',
    'npm uninstall': 'Remove a package',
    
    // Flutter commands
    'flutter': 'Flutter framework CLI',
    'flutter run': 'Run Flutter application',
    'flutter build': 'Build Flutter application',
    'flutter test': 'Run Flutter tests',
    'flutter pub get': 'Get packages',
    'flutter pub upgrade': 'Upgrade packages',
    'flutter clean': 'Delete build files',
    'flutter doctor': 'Show information about Flutter installation',
    'flutter create': 'Create a new Flutter project',
    'flutter analyze': 'Analyze Dart code',
    'flutter format': 'Format Dart code',
    
    // System commands
    'ls': 'List directory contents',
    'cd': 'Change directory',
    'pwd': 'Print working directory',
    'mkdir': 'Make directories',
    'rmdir': 'Remove directories',
    'rm': 'Remove files and directories',
    'cp': 'Copy files or directories',
    'mv': 'Move/rename files or directories',
    'cat': 'Display file contents',
    'grep': 'Search text patterns',
    'find': 'Search for files and directories',
    'chmod': 'Change file permissions',
    'chown': 'Change file ownership',
    'ps': 'Show running processes',
    'kill': 'Terminate processes',
    'top': 'Display running processes',
    'df': 'Display filesystem disk space usage',
    'du': 'Display directory space usage',
    'which': 'Locate a command',
    'whereis': 'Locate binary, source, and manual page files',
    'history': 'Command history',
    'clear': 'Clear terminal screen',
    'exit': 'Exit the terminal',
    
    // Development tools
    'code': 'Open Visual Studio Code',
    'vim': 'Vi IMproved text editor',
    'nano': 'Simple text editor',
    'curl': 'Transfer data from servers',
    'wget': 'Download files from web',
    'ssh': 'Secure Shell',
    'scp': 'Secure copy over network',
    'rsync': 'Synchronize files/directories',
    'tar': 'Archive files',
    'zip': 'Create compressed archives',
    'unzip': 'Extract compressed archives',
    'docker': 'Container platform',
    'docker-compose': 'Multi-container Docker applications',
    
    // Package managers
    'yarn': 'Fast, reliable package manager',
    'pip': 'Python package installer',
    'brew': 'Package manager for macOS',
    'apt': 'Advanced Package Tool',
    'yum': 'Package manager for RPM',
    
    // Build tools
    'make': 'Build automation tool',
    'cmake': 'Cross-platform build system',
    'gradle': 'Build automation tool',
    'maven': 'Project management tool',
    'webpack': 'Module bundler',
    'vite': 'Build tool',
    'rollup': 'Module bundler',
  };

  List<AutocompleteOption> getSuggestions(String input, String currentDirectory) {
    List<AutocompleteOption> suggestions = [];
    
    if (input.isEmpty) {
      return suggestions;
    }

    // Get command suggestions
    suggestions.addAll(_getCommandSuggestions(input));
    
    // Get file/directory suggestions if input contains path-like characters
    if (input.contains('/') || input.contains('.') || input.split(' ').length > 1) {
      suggestions.addAll(_getPathSuggestions(input, currentDirectory));
    }

    // Sort by relevance (exact matches first, then startsWith, then contains)
    suggestions.sort((a, b) {
      int scoreA = _getRelevanceScore(a.text, input);
      int scoreB = _getRelevanceScore(b.text, input);
      return scoreB.compareTo(scoreA);
    });

    // Limit to top 8 suggestions
    return suggestions.take(8).toList();
  }

  List<AutocompleteOption> _getCommandSuggestions(String input) {
    List<AutocompleteOption> suggestions = [];
    String lowercaseInput = input.toLowerCase();
    
    _commonCommands.forEach((command, description) {
      if (command.toLowerCase().contains(lowercaseInput)) {
        suggestions.add(AutocompleteOption(
          text: command,
          description: description,
          type: AutocompleteType.command,
          icon: _getCommandIcon(command),
        ));
      }
    });

    return suggestions;
  }

  List<AutocompleteOption> _getPathSuggestions(String input, String currentDirectory) {
    List<AutocompleteOption> suggestions = [];
    
    try {
      // Extract the path part from the input
      List<String> parts = input.split(' ');
      if (parts.isEmpty) return suggestions;
      
      String lastPart = parts.last;
      String dirPath = currentDirectory;
      String searchTerm = lastPart;
      
      // Handle absolute paths
      if (lastPart.startsWith('/')) {
        List<String> pathParts = lastPart.split('/');
        if (pathParts.length > 1) {
          dirPath = '/' + pathParts.sublist(1, pathParts.length - 1).join('/');
          searchTerm = pathParts.last;
        }
      }
      // Handle relative paths
      else if (lastPart.contains('/')) {
        List<String> pathParts = lastPart.split('/');
        if (pathParts.length > 1) {
          dirPath = path.join(currentDirectory, pathParts.sublist(0, pathParts.length - 1).join('/'));
          searchTerm = pathParts.last;
        }
      }
      
      Directory dir = Directory(dirPath);
      if (dir.existsSync()) {
        List<FileSystemEntity> entities = dir.listSync();
        
        for (var entity in entities) {
          String name = path.basename(entity.path);
          if (name.startsWith('.') && !searchTerm.startsWith('.')) {
            continue; // Skip hidden files unless explicitly searching for them
          }
          
          if (searchTerm.isEmpty || name.toLowerCase().contains(searchTerm.toLowerCase())) {
            String displayName = entity is Directory ? '$name/' : name;
            String fullPath = lastPart.contains('/') ? 
              lastPart.substring(0, lastPart.lastIndexOf('/') + 1) + displayName :
              displayName;
              
            suggestions.add(AutocompleteOption(
              text: fullPath,
              description: entity is Directory ? 'Directory' : 'File',
              type: entity is Directory ? AutocompleteType.directory : AutocompleteType.file,
              icon: entity is Directory ? '📁' : _getFileIcon(name),
            ));
          }
        }
      }
    } catch (e) {
      // Ignore errors in path suggestions
    }
    
    return suggestions;
  }

  int _getRelevanceScore(String option, String input) {
    String lowerOption = option.toLowerCase();
    String lowerInput = input.toLowerCase();
    
    if (lowerOption == lowerInput) return 1000;
    if (lowerOption.startsWith(lowerInput)) return 500;
    if (lowerOption.contains(lowerInput)) return 100;
    return 0;
  }

  String _getCommandIcon(String command) {
    if (command.startsWith('git')) return '🔀';
    if (command.startsWith('npm') || command.startsWith('yarn')) return '📦';
    if (command.startsWith('flutter')) return '🐦';
    if (command.startsWith('docker')) return '🐳';
    if (command == 'cd') return '📁';
    if (command == 'ls') return '📋';
    if (command == 'pwd') return '🗂️';
    if (command.startsWith('mkdir')) return '📁';
    if (command.startsWith('rm')) return '🗑️';
    if (command.startsWith('cp') || command.startsWith('mv')) return '📄';
    if (command.startsWith('cat') || command.startsWith('grep')) return '📝';
    if (command == 'clear') return '🧹';
    if (command.startsWith('make') || command.startsWith('build')) return '🔨';
    if (command == 'code') return '💻';
    if (command == 'vim' || command == 'nano') return '✏️';
    return '⚡';
  }

  String _getFileIcon(String filename) {
    String extension = path.extension(filename).toLowerCase();
    switch (extension) {
      case '.dart': return '🎯';
      case '.js': case '.ts': return '🟨';
      case '.json': return '📋';
      case '.yaml': case '.yml': return '📄';
      case '.md': return '📝';
      case '.png': case '.jpg': case '.jpeg': case '.gif': return '🖼️';
      case '.pdf': return '📕';
      case '.zip': case '.tar': case '.gz': return '📦';
      default: return '📄';
    }
  }
}

class AutocompleteOption {
  final String text;
  final String description;
  final AutocompleteType type;
  final String icon;

  AutocompleteOption({
    required this.text,
    required this.description,
    required this.type,
    required this.icon,
  });
}

enum AutocompleteType {
  command,
  file,
  directory,
  flag,
}