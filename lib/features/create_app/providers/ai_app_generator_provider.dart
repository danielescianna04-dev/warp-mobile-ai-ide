import 'package:flutter/foundation.dart';
import '../../../core/terminal/terminal_service.dart';
import '../../../core/github/github_service.dart';

class GeneratedAppResult {
  final String appName;
  final String packageName;
  final String description;
  final String framework;
  final String projectPath;
  final List<String> features;
  final String? githubUrl;

  GeneratedAppResult({
    required this.appName,
    required this.packageName,
    required this.description,
    required this.framework,
    required this.projectPath,
    required this.features,
    this.githubUrl,
  });
}

class AIAppGeneratorProvider extends ChangeNotifier {
  final TerminalService _terminalService = TerminalService();
  final GitHubService _githubService = GitHubService();

  String _prompt = '';
  bool _isGenerating = false;

  String get prompt => _prompt;
  bool get isGenerating => _isGenerating;

  void updatePrompt(String newPrompt) {
    _prompt = newPrompt;
    notifyListeners();
  }

  Future<GeneratedAppResult?> generateApp() async {
    if (_prompt.trim().isEmpty || _isGenerating) {
      return null;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      // Analizza il prompt e determina i parametri dell'app
      final appParams = await _analyzePrompt(_prompt);
      
      // Genera il progetto
      final projectPath = await _generateProject(appParams);
      
      // Opzionalmente, crea un repository GitHub
      String? githubUrl;
      try {
        githubUrl = await _createGitHubRepository(appParams);
      } catch (e) {
        // GitHub creation is optional, continue even if it fails
        if (kDebugMode) {
          print('GitHub repository creation failed: $e');
        }
      }
      
      return GeneratedAppResult(
        appName: appParams['appName'],
        packageName: appParams['packageName'],
        description: appParams['description'],
        framework: appParams['framework'],
        projectPath: projectPath,
        features: List<String>.from(appParams['features'] ?? []),
        githubUrl: githubUrl,
      );

    } catch (error) {
      if (kDebugMode) {
        print('Error generating app: $error');
      }
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _analyzePrompt(String prompt) async {
    // Simula l'analisi AI del prompt per determinare i parametri
    // In una implementazione reale, questo chiamerebbe un servizio AI
    
    final promptLower = prompt.toLowerCase();
    String appName = _extractAppName(prompt);
    String framework = _determineFramework(promptLower);
    List<String> features = _extractFeatures(promptLower);
    String appType = _determineAppType(promptLower, features);
    
    // Genera un package name basato sul nome dell'app
    String packageName = _generatePackageName(appName);
    
    return {
      'appName': appName,
      'packageName': packageName,
      'description': prompt,
      'framework': framework,
      'appType': appType,
      'features': features,
    };
  }

  String _extractAppName(String prompt) {
    // Logica semplificata per estrarre il nome dell'app dal prompt
    final words = prompt.split(' ');
    
    // Cerca pattern comuni
    for (int i = 0; i < words.length - 1; i++) {
      final word = words[i].toLowerCase();
      if (word == 'app' && i > 0) {
        // Prende la parola prima di "app"
        return _capitalize(words[i - 1].replaceAll(RegExp(r'[^\w\s]'), ''));
      }
      if (word == 'a' || word == 'an' || word == 'the') {
        if (i < words.length - 2 && words[i + 2].toLowerCase() == 'app') {
          return _capitalize(words[i + 1].replaceAll(RegExp(r'[^\w\s]'), ''));
        }
      }
    }
    
    // Fallback: usa parole chiave comuni
    if (prompt.toLowerCase().contains('social')) return 'SocialApp';
    if (prompt.toLowerCase().contains('todo')) return 'TodoApp';
    if (prompt.toLowerCase().contains('chat')) return 'ChatApp';
    if (prompt.toLowerCase().contains('note')) return 'NoteApp';
    if (prompt.toLowerCase().contains('fitness')) return 'FitnessApp';
    if (prompt.toLowerCase().contains('weather')) return 'WeatherApp';
    if (prompt.toLowerCase().contains('music')) return 'MusicApp';
    if (prompt.toLowerCase().contains('photo')) return 'PhotoApp';
    if (prompt.toLowerCase().contains('expense')) return 'ExpenseApp';
    if (prompt.toLowerCase().contains('recipe')) return 'RecipeApp';
    
    return 'MyApp';
  }

  String _determineFramework(String prompt) {
    // Determina il framework migliore basato sul prompt
    if (prompt.contains('flutter') || prompt.contains('dart')) {
      return 'Flutter';
    }
    if (prompt.contains('react native') || prompt.contains('javascript') || prompt.contains('js')) {
      return 'React Native';
    }
    if (prompt.contains('native') && prompt.contains('ios')) {
      return 'iOS Native';
    }
    if (prompt.contains('native') && prompt.contains('android')) {
      return 'Android Native';
    }
    if (prompt.contains('web') || prompt.contains('website') || prompt.contains('browser')) {
      return 'Next.js';
    }
    
    // Default Flutter per mobile apps
    if (prompt.contains('mobile') || prompt.contains('app')) {
      return 'Flutter';
    }
    
    return 'Flutter'; // Default
  }

  List<String> _extractFeatures(String prompt) {
    List<String> features = [];
    
    // Analizza il prompt per features comuni
    if (prompt.contains('auth') || prompt.contains('login') || prompt.contains('sign')) {
      features.add('Authentication');
    }
    if (prompt.contains('database') || prompt.contains('storage') || prompt.contains('save')) {
      features.add('Local Storage');
    }
    if (prompt.contains('api') || prompt.contains('server') || prompt.contains('backend')) {
      features.add('API Integration');
    }
    if (prompt.contains('camera') || prompt.contains('photo') || prompt.contains('image')) {
      features.add('Camera');
    }
    if (prompt.contains('location') || prompt.contains('gps') || prompt.contains('map')) {
      features.add('Location Services');
    }
    if (prompt.contains('notification') || prompt.contains('push')) {
      features.add('Push Notifications');
    }
    if (prompt.contains('offline') || prompt.contains('sync')) {
      features.add('Offline Support');
    }
    if (prompt.contains('share') || prompt.contains('social')) {
      features.add('Social Sharing');
    }
    if (prompt.contains('dark') || prompt.contains('theme')) {
      features.add('Theming');
    }
    if (prompt.contains('payment') || prompt.contains('pay') || prompt.contains('purchase')) {
      features.add('In-App Payments');
    }
    
    return features;
  }

  String _determineAppType(String prompt, List<String> features) {
    if (prompt.contains('web') || prompt.contains('website') || prompt.contains('browser')) {
      return 'web';
    }
    if (prompt.contains('desktop') || prompt.contains('windows') || prompt.contains('mac')) {
      return 'desktop';
    }
    return 'mobile'; // Default
  }

  String _generatePackageName(String appName) {
    // Converte il nome dell'app in un package name valido
    final cleanName = appName.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
    return 'com.company.$cleanName';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<String> _generateProject(Map<String, dynamic> params) async {
    final framework = params['framework'] as String;
    final appName = params['appName'] as String;
    final packageName = params['packageName'] as String;
    final features = params['features'] as List<String>;
    
    // Simula la generazione del progetto basata sul framework
    String command = '';
    
    switch (framework) {
      case 'Flutter':
        command = 'flutter create --project-name ${_sanitizeProjectName(appName)} $appName';
        break;
      case 'React Native':
        command = 'npx react-native init $appName';
        break;
      case 'Next.js':
        command = 'npx create-next-app@latest $appName --typescript --tailwind --eslint --app';
        break;
      case 'iOS Native':
        command = 'xcodegen generate --project $appName';
        break;
      case 'Android Native':
        command = 'gradle init --type java-application --project-name $appName';
        break;
      default:
        command = 'flutter create --project-name ${_sanitizeProjectName(appName)} $appName';
    }
    
    // Esegui il comando di generazione
    await _terminalService.executeCommand(command);
    
    // Simula l'aggiunta delle features richieste
    for (final feature in features) {
      await _addFeatureToProject(appName, feature, framework);
    }
    
    return './$appName'; // Path relativo del progetto
  }

  String _sanitizeProjectName(String name) {
    // Sanitizza il nome del progetto per Flutter
    return name.toLowerCase().replaceAll(RegExp(r'[^\w]'), '_');
  }

  Future<void> _addFeatureToProject(String projectName, String feature, String framework) async {
    // Simula l'aggiunta di features specifiche al progetto
    switch (feature) {
      case 'Authentication':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add firebase_auth');
        }
        break;
      case 'Local Storage':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add sqflite shared_preferences');
        }
        break;
      case 'API Integration':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add http dio');
        }
        break;
      case 'Camera':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add camera image_picker');
        }
        break;
      case 'Location Services':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add geolocator location');
        }
        break;
      case 'Push Notifications':
        if (framework == 'Flutter') {
          await _terminalService.executeCommand('cd $projectName && flutter pub add firebase_messaging');
        }
        break;
      // Aggiungi altre features secondo necessità
    }
  }

  Future<String?> _createGitHubRepository(Map<String, dynamic> params) async {
    final appName = params['appName'] as String;
    final description = params['description'] as String;
    
    try {
      final result = await _githubService.createRepository(
        appName,
        description: description,
        isPrivate: false,
      );
      
      return result?.htmlUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create GitHub repository: $e');
      }
      return null;
    }
  }
}