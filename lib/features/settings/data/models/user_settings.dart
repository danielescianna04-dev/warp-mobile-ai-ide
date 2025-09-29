class UserSettings {
  final String userId;
  final UserProfile profile;
  final AppPreferences preferences;
  final AISettings aiSettings;
  final SecuritySettings security;
  final GitHubSettings github;

  UserSettings({
    required this.userId,
    required this.profile,
    required this.preferences,
    required this.aiSettings,
    required this.security,
    required this.github,
  });

  UserSettings copyWith({
    String? userId,
    UserProfile? profile,
    AppPreferences? preferences,
    AISettings? aiSettings,
    SecuritySettings? security,
    GitHubSettings? github,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      aiSettings: aiSettings ?? this.aiSettings,
      security: security ?? this.security,
      github: github ?? this.github,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profile': profile.toJson(),
      'preferences': preferences.toJson(),
      'aiSettings': aiSettings.toJson(),
      'security': security.toJson(),
      'github': github.toJson(),
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'] ?? '',
      profile: UserProfile.fromJson(json['profile'] ?? {}),
      preferences: AppPreferences.fromJson(json['preferences'] ?? {}),
      aiSettings: AISettings.fromJson(json['aiSettings'] ?? {}),
      security: SecuritySettings.fromJson(json['security'] ?? {}),
      github: GitHubSettings.fromJson(json['github'] ?? {}),
    );
  }

  static UserSettings defaultSettings() {
    return UserSettings(
      userId: '',
      profile: UserProfile.defaultProfile(),
      preferences: AppPreferences.defaultPreferences(),
      aiSettings: AISettings.defaultSettings(),
      security: SecuritySettings.defaultSettings(),
      github: GitHubSettings.defaultSettings(),
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? company;
  final String? location;

  UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.company,
    this.location,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? company,
    String? location,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'company': company,
      'location': location,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      company: json['company'],
      location: json['location'],
    );
  }

  static UserProfile defaultProfile() {
    return UserProfile(
      name: 'Developer',
      email: '',
    );
  }
}

class AppPreferences {
  final String theme; // 'dark', 'light', 'system'
  final String language;
  final bool enableHapticFeedback;
  final bool enableAnimations;
  final double fontSize;
  final String fontFamily;
  final bool enableSidebarBlur;
  final bool autoSaveChats;
  final int maxChatHistory;

  AppPreferences({
    required this.theme,
    required this.language,
    required this.enableHapticFeedback,
    required this.enableAnimations,
    required this.fontSize,
    required this.fontFamily,
    required this.enableSidebarBlur,
    required this.autoSaveChats,
    required this.maxChatHistory,
  });

  AppPreferences copyWith({
    String? theme,
    String? language,
    bool? enableHapticFeedback,
    bool? enableAnimations,
    double? fontSize,
    String? fontFamily,
    bool? enableSidebarBlur,
    bool? autoSaveChats,
    int? maxChatHistory,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      enableSidebarBlur: enableSidebarBlur ?? this.enableSidebarBlur,
      autoSaveChats: autoSaveChats ?? this.autoSaveChats,
      maxChatHistory: maxChatHistory ?? this.maxChatHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'enableHapticFeedback': enableHapticFeedback,
      'enableAnimations': enableAnimations,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'enableSidebarBlur': enableSidebarBlur,
      'autoSaveChats': autoSaveChats,
      'maxChatHistory': maxChatHistory,
    };
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      theme: json['theme'] ?? 'dark',
      language: json['language'] ?? 'it',
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      enableAnimations: json['enableAnimations'] ?? true,
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      fontFamily: json['fontFamily'] ?? 'SF Mono',
      enableSidebarBlur: json['enableSidebarBlur'] ?? true,
      autoSaveChats: json['autoSaveChats'] ?? true,
      maxChatHistory: json['maxChatHistory'] ?? 50,
    );
  }

  static AppPreferences defaultPreferences() {
    return AppPreferences(
      theme: 'dark',
      language: 'it',
      enableHapticFeedback: true,
      enableAnimations: true,
      fontSize: 14.0,
      fontFamily: 'SF Mono',
      enableSidebarBlur: true,
      autoSaveChats: true,
      maxChatHistory: 50,
    );
  }
}

class AISettings {
  final String defaultModel;
  final double temperature;
  final int maxTokens;
  final bool enableStreamResponse;
  final bool enableContextMemory;
  final List<String> favoriteModels;

  AISettings({
    required this.defaultModel,
    required this.temperature,
    required this.maxTokens,
    required this.enableStreamResponse,
    required this.enableContextMemory,
    required this.favoriteModels,
  });

  AISettings copyWith({
    String? defaultModel,
    double? temperature,
    int? maxTokens,
    bool? enableStreamResponse,
    bool? enableContextMemory,
    List<String>? favoriteModels,
  }) {
    return AISettings(
      defaultModel: defaultModel ?? this.defaultModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      enableStreamResponse: enableStreamResponse ?? this.enableStreamResponse,
      enableContextMemory: enableContextMemory ?? this.enableContextMemory,
      favoriteModels: favoriteModels ?? this.favoriteModels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultModel': defaultModel,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'enableStreamResponse': enableStreamResponse,
      'enableContextMemory': enableContextMemory,
      'favoriteModels': favoriteModels,
    };
  }

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      defaultModel: json['defaultModel'] ?? 'claude-3-sonnet',
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      maxTokens: json['maxTokens'] ?? 4096,
      enableStreamResponse: json['enableStreamResponse'] ?? true,
      enableContextMemory: json['enableContextMemory'] ?? true,
      favoriteModels: List<String>.from(json['favoriteModels'] ?? ['claude-3-sonnet', 'gpt-4']),
    );
  }

  static AISettings defaultSettings() {
    return AISettings(
      defaultModel: 'claude-3-sonnet',
      temperature: 0.7,
      maxTokens: 4096,
      enableStreamResponse: true,
      enableContextMemory: true,
      favoriteModels: ['claude-3-sonnet', 'gpt-4'],
    );
  }
}

class SecuritySettings {
  final bool enableBiometrics;
  final bool requireAuthForSettings;
  final bool enableDataEncryption;
  final int sessionTimeout; // in minutes
  final bool allowScreenshots;

  SecuritySettings({
    required this.enableBiometrics,
    required this.requireAuthForSettings,
    required this.enableDataEncryption,
    required this.sessionTimeout,
    required this.allowScreenshots,
  });

  SecuritySettings copyWith({
    bool? enableBiometrics,
    bool? requireAuthForSettings,
    bool? enableDataEncryption,
    int? sessionTimeout,
    bool? allowScreenshots,
  }) {
    return SecuritySettings(
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      requireAuthForSettings: requireAuthForSettings ?? this.requireAuthForSettings,
      enableDataEncryption: enableDataEncryption ?? this.enableDataEncryption,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      allowScreenshots: allowScreenshots ?? this.allowScreenshots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableBiometrics': enableBiometrics,
      'requireAuthForSettings': requireAuthForSettings,
      'enableDataEncryption': enableDataEncryption,
      'sessionTimeout': sessionTimeout,
      'allowScreenshots': allowScreenshots,
    };
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      enableBiometrics: json['enableBiometrics'] ?? false,
      requireAuthForSettings: json['requireAuthForSettings'] ?? false,
      enableDataEncryption: json['enableDataEncryption'] ?? true,
      sessionTimeout: json['sessionTimeout'] ?? 30,
      allowScreenshots: json['allowScreenshots'] ?? true,
    );
  }

  static SecuritySettings defaultSettings() {
    return SecuritySettings(
      enableBiometrics: false,
      requireAuthForSettings: false,
      enableDataEncryption: true,
      sessionTimeout: 30,
      allowScreenshots: true,
    );
  }
}

class GitHubSettings {
  final String? accessToken;
  final String? username;
  final bool enableAutoSync;
  final bool enableNotifications;
  final List<String> favoriteRepositories;

  GitHubSettings({
    this.accessToken,
    this.username,
    required this.enableAutoSync,
    required this.enableNotifications,
    required this.favoriteRepositories,
  });

  GitHubSettings copyWith({
    String? accessToken,
    String? username,
    bool? enableAutoSync,
    bool? enableNotifications,
    List<String>? favoriteRepositories,
  }) {
    return GitHubSettings(
      accessToken: accessToken ?? this.accessToken,
      username: username ?? this.username,
      enableAutoSync: enableAutoSync ?? this.enableAutoSync,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      favoriteRepositories: favoriteRepositories ?? this.favoriteRepositories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'username': username,
      'enableAutoSync': enableAutoSync,
      'enableNotifications': enableNotifications,
      'favoriteRepositories': favoriteRepositories,
    };
  }

  factory GitHubSettings.fromJson(Map<String, dynamic> json) {
    return GitHubSettings(
      accessToken: json['accessToken'],
      username: json['username'],
      enableAutoSync: json['enableAutoSync'] ?? false,
      enableNotifications: json['enableNotifications'] ?? true,
      favoriteRepositories: List<String>.from(json['favoriteRepositories'] ?? []),
    );
  }

  static GitHubSettings defaultSettings() {
    return GitHubSettings(
      enableAutoSync: false,
      enableNotifications: true,
      favoriteRepositories: [],
    );
  }
}