import 'package:flutter/material.dart';
import '../../../core/wizard/create_app_models.dart';
import '../../../core/wizard/preset_apps.dart';
import '../../../core/terminal/terminal_service.dart';
import '../../../core/github/github_service.dart';

class CreateAppWizardProvider extends ChangeNotifier {
  CreateAppWizardData _wizardData = const CreateAppWizardData();
  int _currentStep = 0;
  bool _isGenerating = false;
  String? _generationError;
  
  // Total number of steps in the wizard
  static const int totalSteps = 6;
  
  // Getters
  CreateAppWizardData get wizardData => _wizardData;
  int get currentStep => _currentStep;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;
  bool get canGoNext => isCurrentStepValid && _currentStep < totalSteps - 1;
  bool get canGoBack => _currentStep > 0 && !_isGenerating;
  bool get isLastStep => _currentStep == totalSteps - 1;
  bool get canCreateApp => _wizardData.isStepValid(totalSteps - 1);
  
  double get progress => (_currentStep + 1) / totalSteps;
  
  String get currentStepTitle {
    switch (_currentStep) {
      case 0:
        return 'Scegli Template';
      case 1:
        return _wizardData.isCustomFlow ? 'Tipo Applicazione' : 'Riepilogo';
      case 2:
        return 'Framework';
      case 3:
        return 'Funzionalità';
      case 4:
        return 'Template';
      case 5:
        return 'Riepilogo';
      default:
        return 'Wizard';
    }
  }
  
  String get currentStepDescription {
    switch (_currentStep) {
      case 0:
        return 'Seleziona il tipo di app che vuoi creare';
      case 1:
        return _wizardData.isCustomFlow 
            ? 'Seleziona su quale piattaforma verrà eseguita' 
            : 'Verifica i dettagli e crea il progetto';
      case 2:
        return 'Scegli il framework di sviluppo';
      case 3:
        return 'Aggiungi le funzionalità che ti servono';
      case 4:
        return 'Scegli un template di partenza';
      case 5:
        return 'Verifica i dettagli e crea il progetto';
      default:
        return '';
    }
  }
  
  bool get isCurrentStepValid {
    return _wizardData.isStepValid(_currentStep);
  }
  
  // Navigation methods (il metodo nextStep è definito dopo i preset methods)
  
  void previousStep() {
    if (canGoBack) {
      _currentStep--;
      _clearError();
      notifyListeners();
    }
  }
  
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps && !_isGenerating) {
      _currentStep = step;
      _clearError();
      notifyListeners();
    }
  }
  
  // Data update methods
  void updateAppName(String name) {
    _wizardData = _wizardData.copyWith(appName: name);
    _updatePackageNameIfEmpty(name);
    _clearError();
    notifyListeners();
  }
  
  void updatePackageName(String packageName) {
    _wizardData = _wizardData.copyWith(packageName: packageName);
    _clearError();
    notifyListeners();
  }
  
  void updateDescription(String description) {
    _wizardData = _wizardData.copyWith(description: description);
    _clearError();
    notifyListeners();
  }
  
  void updateAppType(AppType appType) {
    _wizardData = _wizardData.copyWith(
      appType: appType,
      framework: null, // Reset framework when app type changes
    );
    _clearError();
    notifyListeners();
  }
  
  void updateFramework(Framework framework) {
    _wizardData = _wizardData.copyWith(framework: framework);
    _clearError();
    notifyListeners();
  }
  
  void toggleFeature(AppFeature feature) {
    List<AppFeature> currentFeatures = List.from(_wizardData.features);
    if (currentFeatures.contains(feature)) {
      currentFeatures.remove(feature);
    } else {
      currentFeatures.add(feature);
    }
    _wizardData = _wizardData.copyWith(features: currentFeatures);
    _clearError();
    notifyListeners();
  }
  
  void updateTemplate(AppTemplate template) {
    _wizardData = _wizardData.copyWith(template: template);
    _clearError();
    notifyListeners();
  }
  
  void updateThemeConfig(AppThemeConfig themeConfig) {
    _wizardData = _wizardData.copyWith(themeConfig: themeConfig);
    _clearError();
    notifyListeners();
  }
  
  void updateUseGitRepository(bool useGit) {
    _wizardData = _wizardData.copyWith(useGitRepository: useGit);
    _clearError();
    notifyListeners();
  }
  
  void updateGitRepositoryName(String? repoName) {
    _wizardData = _wizardData.copyWith(gitRepositoryName: repoName);
    _clearError();
    notifyListeners();
  }
  
  // Preset management methods
  void selectPreset(PresetAppType presetType) {
    final config = PresetAppsRepository.getConfig(presetType);
    if (config == null) return;
    
    if (presetType == PresetAppType.custom) {
      // Seleziona il flusso custom
      _wizardData = _wizardData.copyWith(
        selectedPreset: 'custom',
      );
    } else {
      // Applica la configurazione del preset
      _wizardData = _wizardData.copyWith(
        selectedPreset: presetType.name,
        appType: _parseAppType(config.appType),
        framework: _parseFramework(config.framework),
        features: config.features.map((f) => _parseFeature(f)).where((f) => f != null).cast<AppFeature>().toList(),
        template: _suggestTemplate(config.features),
      );
    }
    
    _clearError();
    notifyListeners();
  }
  
  // Helper methods for parsing preset configurations
  AppType _parseAppType(String appTypeString) {
    switch (appTypeString.toLowerCase()) {
      case 'mobile':
        return AppType.mobile;
      case 'web':
        return AppType.web;
      case 'desktop':
        return AppType.desktop;
      default:
        return AppType.mobile;
    }
  }
  
  Framework? _parseFramework(String frameworkString) {
    switch (frameworkString.toLowerCase()) {
      case 'flutter':
        return Framework.flutter;
      case 'react':
        return Framework.react;
      case 'nextjs':
        return Framework.nextjs;
      case 'vue':
        return Framework.vue;
      case 'angular':
        return Framework.angular;
      case 'svelte':
        return Framework.svelte;
      case 'react_native':
        return Framework.reactNative;
      case 'ionic':
        return Framework.ionic;
      case 'electron':
        return Framework.electron;
      case 'tauri':
        return Framework.tauri;
      default:
        return Framework.flutter;
    }
  }
  
  AppFeature? _parseFeature(String featureString) {
    switch (featureString.toLowerCase()) {
      case 'markdown':
      case 'ai_integration':
        return AppFeature.api;
      case 'cloud_sync':
      case 'sync':
        return AppFeature.database;
      case 'search':
        return AppFeature.analytics;
      case 'tags':
        return AppFeature.database;
      case 'offline_mode':
      case 'offline_play':
        return AppFeature.fileStorage;
      case 'chat_history':
        return AppFeature.chat;
      case 'voice_input':
        return AppFeature.camera;
      case 'markdown_support':
        return AppFeature.fileStorage;
      case 'themes':
        return AppFeature.darkMode;
      case 'maps':
        return AppFeature.maps;
      case 'filters':
        return AppFeature.api;
      case 'booking':
      case 'payments':
        return AppFeature.payments;
      case 'reviews':
        return AppFeature.socialLogin;
      case 'game_logic':
      case 'statistics':
      case 'daily_challenge':
        return AppFeature.analytics;
      case 'animations':
        return null; // Non abbiamo questa feature specifica
      case 'task_management':
        return AppFeature.pushNotifications;
      case 'categories':
        return AppFeature.database;
      case 'notifications':
        return AppFeature.pushNotifications;
      case 'calendar':
        return AppFeature.api;
      case 'weather_api':
        return AppFeature.api;
      case 'location':
        return AppFeature.maps;
      case 'forecasts':
        return AppFeature.api;
      case 'widgets':
        return AppFeature.analytics;
      case 'product_catalog':
      case 'cart':
        return AppFeature.database;
      case 'orders':
        return AppFeature.api;
      case 'wishlist':
        return AppFeature.database;
      case 'audio_player':
      case 'playlists':
        return AppFeature.fileStorage;
      case 'equalizer':
        return null; // Feature specifica
      case 'streaming':
        return AppFeature.api;
      case 'lyrics':
        return AppFeature.api;
      default:
        return null;
    }
  }
  
  AppTemplate? _suggestTemplate(List<String> features) {
    if (features.contains('payments') || features.contains('cart')) {
      return AppTemplate.ecommerce;
    }
    if (features.contains('chat_history') || features.contains('reviews')) {
      return AppTemplate.social;
    }
    if (features.contains('task_management') || features.contains('notifications')) {
      return AppTemplate.productivity;
    }
    if (features.contains('game_logic')) {
      return AppTemplate.blank; // Per i giochi
    }
    if (features.contains('weather_api')) {
      return AppTemplate.material; // Per app meteo
    }
    return AppTemplate.material;
  }
  
  // Navigazione intelligente per i preset
  void nextStep() {
    if (canGoNext) {
      // Se abbiamo un preset selezionato (non custom), saltiamo alcuni step
      if (_wizardData.isPresetSelected && _currentStep == 1) {
        // Dal preset selection, vai direttamente al summary
        _currentStep = totalSteps - 1; // Vai al summary
      } else {
        _currentStep++;
      }
      _clearError();
      notifyListeners();
    }
  }
  
  // Helper methods
  void _updatePackageNameIfEmpty(String appName) {
    if (_wizardData.packageName.isEmpty && appName.isNotEmpty) {
      _wizardData = _wizardData.copyWith(
        packageName: _wizardData.autoGeneratedPackageName,
      );
    }
  }
  
  void _clearError() {
    if (_generationError != null) {
      _generationError = null;
      notifyListeners();
    }
  }
  
  // Get compatible frameworks based on selected app type
  List<Framework> get compatibleFrameworks {
    return Framework.getCompatibleFrameworks(_wizardData.appType);
  }
  
  // Get recommended templates based on app type and features
  List<AppTemplate> get recommendedTemplates {
    return AppTemplate.getRecommendedTemplates(
      _wizardData.appType,
      _wizardData.features,
    );
  }
  
  // Validation methods for UI feedback
  String? validateAppName(String name) {
    if (name.trim().isEmpty) {
      return 'Il nome dell\'app è obbligatorio';
    }
    if (name.trim().length < 3) {
      return 'Il nome deve contenere almeno 3 caratteri';
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name.trim())) {
      return 'Il nome può contenere solo lettere, numeri e underscore';
    }
    return null;
  }
  
  String? validatePackageName(String packageName) {
    if (packageName.trim().isEmpty) {
      return 'Il package name è obbligatorio';
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(packageName.trim())) {
      return 'Formato package name non valido (es. com.company.app)';
    }
    return null;
  }
  
  String? validateDescription(String description) {
    if (description.trim().isEmpty) {
      return 'La descrizione è obbligatoria';
    }
    if (description.trim().length < 10) {
      return 'La descrizione deve contenere almeno 10 caratteri';
    }
    return null;
  }
  
  // Generate project
  Future<void> generateProject() async {
    if (!canCreateApp || _isGenerating) return;
    
    try {
      _isGenerating = true;
      _generationError = null;
      notifyListeners();
      
      // Generate the create command
      String command = _wizardData.generateCreateCommand();
      
      if (command.isEmpty) {
        throw Exception('Impossibile generare il comando di creazione');
      }
      
      // Execute the command using TerminalService
      final terminalService = TerminalService();
      
      // If using Git repository, we might need additional setup
      if (_wizardData.useGitRepository && _wizardData.gitRepositoryName != null) {
        // First create the project
        await terminalService.executeCommand(command);
        
        // Then initialize git and create repository
        await _setupGitRepository();
      } else {
        // Just create the project
        await terminalService.executeCommand(command);
      }
      
      // Project created successfully
      _isGenerating = false;
      notifyListeners();
      
    } catch (error) {
      _isGenerating = false;
      _generationError = error.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> _setupGitRepository() async {
    if (_wizardData.gitRepositoryName == null) return;
    
    final terminalService = TerminalService();
    
    // Initialize git in the project directory
    await terminalService.executeCommand(
      'cd ${_wizardData.appName.toLowerCase()} && git init',
    );
    
    // Add initial commit
    await terminalService.executeCommand(
      'cd ${_wizardData.appName.toLowerCase()} && git add . && git commit -m \"Initial commit\"',
    );
    
    // Create GitHub repository if needed
    if (_wizardData.useGitRepository) {
      try {
        final gitHubService = GitHubService();
        // Create repository on GitHub
        // Note: This would require GitHub API integration
        await gitHubService.createRepository(_wizardData.gitRepositoryName!);
        
        // Add remote origin
        await terminalService.executeCommand(
          'cd ${_wizardData.appName.toLowerCase()} && git remote add origin https://github.com/username/${_wizardData.gitRepositoryName}.git',
        );
        
        // Push to remote
        await terminalService.executeCommand(
          'cd ${_wizardData.appName.toLowerCase()} && git push -u origin main',
        );
      } catch (e) {
        // GitHub setup failed, but project was created locally
        print('GitHub setup failed: $e');
      }
    }
  }
  
  // Reset wizard to initial state
  void reset() {
    _wizardData = const CreateAppWizardData();
    _currentStep = 0;
    _isGenerating = false;
    _generationError = null;
    notifyListeners();
  }
  
  // Export wizard data for debugging or persistence
  Map<String, dynamic> exportData() {
    return {
      'wizardData': _wizardData.toJson(),
      'currentStep': _currentStep,
      'isGenerating': _isGenerating,
      'generationError': _generationError,
    };
  }
  
  // Quick setup methods for common configurations
  void setupFlutterMobileApp() {
    _wizardData = const CreateAppWizardData(
      appType: AppType.mobile,
      framework: Framework.flutter,
      features: [
        AppFeature.authentication,
        AppFeature.database,
        AppFeature.darkMode,
      ],
      template: AppTemplate.material,
    );
    notifyListeners();
  }
  
  void setupReactWebApp() {
    _wizardData = const CreateAppWizardData(
      appType: AppType.web,
      framework: Framework.react,
      features: [
        AppFeature.api,
        AppFeature.authentication,
        AppFeature.darkMode,
      ],
      template: AppTemplate.blank,
    );
    notifyListeners();
  }
  
  void setupElectronDesktopApp() {
    _wizardData = const CreateAppWizardData(
      appType: AppType.desktop,
      framework: Framework.electron,
      features: [
        AppFeature.fileStorage,
        AppFeature.darkMode,
        AppFeature.analytics,
      ],
      template: AppTemplate.productivity,
    );
    notifyListeners();
  }
}