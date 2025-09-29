enum AppType {
  mobile('📱', 'App Mobile', 'Un\'applicazione per dispositivi mobili iOS e Android'),
  desktop('🖥️', 'App Desktop', 'Un\'applicazione per computer Windows, macOS e Linux'),
  web('🌐', 'Sito Web', 'Un\'applicazione web accessibile da browser');

  const AppType(this.icon, this.title, this.description);
  
  final String icon;
  final String title;
  final String description;
}

enum Framework {
  flutter('Flutter', 'Dart', '🚀', 'Framework Google per app native multipiattaforma'),
  react('React', 'JavaScript', '⚛️', 'Libreria JavaScript per interfacce utente'),
  nextjs('Next.js', 'JavaScript', '▲', 'Framework React per applicazioni web moderne'),
  vue('Vue.js', 'JavaScript', '💚', 'Framework JavaScript progressivo e performante'),
  angular('Angular', 'TypeScript', '🔺', 'Piattaforma per applicazioni web enterprise'),
  svelte('Svelte', 'JavaScript', '🧡', 'Framework compile-time per web app veloci'),
  reactNative('React Native', 'JavaScript', '📱', 'Framework per app mobile native con React'),
  ionic('Ionic', 'JavaScript', '⚡', 'Toolkit per app mobile ibride multipiattaforma'),
  electron('Electron', 'JavaScript', '🖥️', 'Framework per app desktop con tecnologie web'),
  tauri('Tauri', 'Rust', '🦀', 'Framework leggero per app desktop con Rust');

  const Framework(this.name, this.language, this.icon, this.description);
  
  final String name;
  final String language;
  final String icon;
  final String description;
  
  static List<Framework> getCompatibleFrameworks(AppType appType) {
    switch (appType) {
      case AppType.mobile:
        return [Framework.flutter, Framework.reactNative, Framework.ionic];
      case AppType.desktop:
        return [Framework.flutter, Framework.electron, Framework.tauri];
      case AppType.web:
        return [Framework.flutter, Framework.react, Framework.nextjs, Framework.vue, Framework.angular, Framework.svelte];
    }
  }
}

enum AppFeature {
  authentication('🔐', 'Autenticazione', 'Sistema di login e registrazione utenti'),
  database('💾', 'Database', 'Persistenza dati locale o cloud'),
  api('🌐', 'API Integration', 'Integrazione con API REST/GraphQL'),
  pushNotifications('🔔', 'Notifiche Push', 'Sistema di notifiche in tempo reale'),
  payments('💳', 'Pagamenti', 'Integrazione gateway di pagamento'),
  maps('🗺️', 'Mappe', 'Integrazione servizi di mappatura'),
  camera('📷', 'Fotocamera', 'Accesso fotocamera e gestione foto'),
  fileStorage('📁', 'File Storage', 'Upload e gestione file cloud'),
  analytics('📊', 'Analytics', 'Tracking e analisi comportamento utenti'),
  socialLogin('👥', 'Login Social', 'Login con Google, Facebook, etc.'),
  chat('💬', 'Chat/Messaging', 'Sistema di messaggistica in tempo reale'),
  darkMode('🌙', 'Tema Scuro', 'Supporto per tema chiaro/scuro');

  const AppFeature(this.icon, this.title, this.description);
  
  final String icon;
  final String title; 
  final String description;
}

enum AppTemplate {
  blank('📝', 'Progetto Vuoto', 'Inizia da zero con la struttura base'),
  material('🎨', 'Material Design', 'Template con componenti Material Design'),
  cupertino('🍎', 'Cupertino Design', 'Template con design iOS nativo'),
  ecommerce('🛒', 'E-Commerce', 'Template per app di shopping online'),
  social('📱', 'Social Media', 'Template per app social con feed e profili'),
  productivity('✅', 'Produttività', 'Template per app di task e project management'),
  fitness('🏃', 'Fitness & Health', 'Template per app di fitness e salute'),
  finance('💰', 'Fintech', 'Template per app finanziarie e banking'),
  news('📰', 'News & Media', 'Template per app di notizie e contenuti'),
  education('🎓', 'Education', 'Template per piattaforme educative');

  const AppTemplate(this.icon, this.title, this.description);
  
  final String icon;
  final String title;
  final String description;
  
  static List<AppTemplate> getRecommendedTemplates(AppType appType, List<AppFeature> features) {
    // Logica per suggerire template in base al tipo di app e features selezionate
    List<AppTemplate> recommended = [];
    
    if (features.contains(AppFeature.payments) || features.contains(AppFeature.api)) {
      recommended.add(AppTemplate.ecommerce);
    }
    
    if (features.contains(AppFeature.chat) || features.contains(AppFeature.socialLogin)) {
      recommended.add(AppTemplate.social);
    }
    
    if (features.contains(AppFeature.analytics) || features.contains(AppFeature.pushNotifications)) {
      recommended.add(AppTemplate.productivity);
    }
    
    if (recommended.isEmpty) {
      recommended = [AppTemplate.blank, AppTemplate.material, AppTemplate.cupertino];
    }
    
    return recommended;
  }
}

class AppThemeConfig {
  final String primaryColor;
  final String accentColor;
  final String appIcon;
  final bool isDarkModeDefault;
  final String fontFamily;
  
  const AppThemeConfig({
    this.primaryColor = '#6366F1', // Indigo di default
    this.accentColor = '#8B5CF6',  // Purple di default
    this.appIcon = '🚀',
    this.isDarkModeDefault = false,
    this.fontFamily = 'SF Pro',
  });
  
  AppThemeConfig copyWith({
    String? primaryColor,
    String? accentColor,
    String? appIcon,
    bool? isDarkModeDefault,
    String? fontFamily,
  }) {
    return AppThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      appIcon: appIcon ?? this.appIcon,
      isDarkModeDefault: isDarkModeDefault ?? this.isDarkModeDefault,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class CreateAppWizardData {
  final String appName;
  final String packageName;
  final String description;
  final AppType appType;
  final Framework? framework;
  final List<AppFeature> features;
  final AppTemplate? template;
  final AppThemeConfig themeConfig;
  final bool useGitRepository;
  final String? gitRepositoryName;
  
  const CreateAppWizardData({
    this.appName = '',
    this.packageName = '',
    this.description = '',
    this.appType = AppType.mobile,
    this.framework,
    this.features = const [],
    this.template,
    this.themeConfig = const AppThemeConfig(),
    this.useGitRepository = false,
    this.gitRepositoryName,
  });
  
  CreateAppWizardData copyWith({
    String? appName,
    String? packageName,
    String? description,
    AppType? appType,
    Framework? framework,
    List<AppFeature>? features,
    AppTemplate? template,
    AppThemeConfig? themeConfig,
    bool? useGitRepository,
    String? gitRepositoryName,
  }) {
    return CreateAppWizardData(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      description: description ?? this.description,
      appType: appType ?? this.appType,
      framework: framework ?? this.framework,
      features: features ?? this.features,
      template: template ?? this.template,
      themeConfig: themeConfig ?? this.themeConfig,
      useGitRepository: useGitRepository ?? this.useGitRepository,
      gitRepositoryName: gitRepositoryName ?? this.gitRepositoryName,
    );
  }
  
  // Validation methods
  bool get isNameValid => appName.trim().length >= 3 && RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(appName.trim());
  
  bool get isPackageNameValid => packageName.trim().isNotEmpty && RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(packageName.trim());
  
  bool get isDescriptionValid => description.trim().length >= 10;
  
  bool get isFrameworkSelected => framework != null;
  
  bool get hasMinimumFeatures => features.length >= 1;
  
  bool get isTemplateSelected => template != null;
  
  String get autoGeneratedPackageName {
    if (appName.trim().isEmpty) return '';
    String cleanName = appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'com.warp.$cleanName';
  }
  
  // Step validation
  bool isStepValid(int step) {
    switch (step) {
      case 0: // Name step
        return isNameValid;
      case 1: // App type step  
        return true; // sempre valido, ha default
      case 2: // Framework step
        return isFrameworkSelected;
      case 3: // Features step
        return hasMinimumFeatures;
      case 4: // Template step
        return isTemplateSelected;
      case 5: // Theme step
        return true; // sempre valido, ha default
      case 6: // Summary step
        return isNameValid && isFrameworkSelected && hasMinimumFeatures && isTemplateSelected;
      default:
        return false;
    }
  }
  
  // Command generation for terminal execution
  String generateCreateCommand() {
    if (!isFrameworkSelected) return '';
    
    switch (framework!) {
      case Framework.flutter:
        return 'flutter create ${appName.toLowerCase()} --org ${packageName.split('.').take(2).join('.')}';
      case Framework.react:
        return 'npx create-react-app ${appName.toLowerCase()}';
      case Framework.nextjs:
        return 'npx create-next-app@latest ${appName.toLowerCase()} --typescript --tailwind --eslint';
      case Framework.vue:
        return 'npm create vue@latest ${appName.toLowerCase()}';
      case Framework.angular:
        return 'ng new ${appName.toLowerCase()} --routing --style=scss';
      case Framework.svelte:
        return 'npm create svelte@latest ${appName.toLowerCase()}';
      case Framework.reactNative:
        return 'npx react-native init ${appName.replaceAll(' ', '')}';
      case Framework.ionic:
        return 'ionic start ${appName.toLowerCase()} blank --type=react';
      case Framework.electron:
        return 'npm create @quick-start/electron ${appName.toLowerCase()}';
      case Framework.tauri:
        return 'cargo create-tauri-app --name ${appName.toLowerCase()}';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'description': description,
      'appType': appType.name,
      'framework': framework?.name,
      'features': features.map((f) => f.name).toList(),
      'template': template?.name,
      'themeConfig': {
        'primaryColor': themeConfig.primaryColor,
        'accentColor': themeConfig.accentColor,
        'appIcon': themeConfig.appIcon,
        'isDarkModeDefault': themeConfig.isDarkModeDefault,
        'fontFamily': themeConfig.fontFamily,
      },
      'useGitRepository': useGitRepository,
      'gitRepositoryName': gitRepositoryName,
    };
  }
}