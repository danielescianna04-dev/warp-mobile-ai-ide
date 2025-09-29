import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../data/models/user_settings.dart';

class SettingsPage extends StatefulWidget {
  final UserSettings? initialSettings;

  const SettingsPage({
    super.key,
    this.initialSettings,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserSettings _settings = UserSettings.defaultSettings();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSettings();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsJson = await _secureStorage.read(key: 'user_settings');
      if (settingsJson != null) {
        final settings = UserSettings.fromJson(jsonDecode(settingsJson));
        setState(() {
          _settings = settings;
          _updateControllers();
        });
      } else if (widget.initialSettings != null) {
        setState(() {
          _settings = widget.initialSettings!;
          _updateControllers();
        });
      }
    } catch (e) {
      // Usa impostazioni predefinite se c'è un errore
      setState(() {
        _settings = UserSettings.defaultSettings();
        _updateControllers();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateControllers() {
    _nameController.text = _settings.profile.name;
    _emailController.text = _settings.profile.email;
    _bioController.text = _settings.profile.bio ?? '';
    _companyController.text = _settings.profile.company ?? '';
    _locationController.text = _settings.profile.location ?? '';
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      HapticFeedback.lightImpact();
      
      // Aggiorna le impostazioni con i valori dei controller
      final updatedProfile = _settings.profile.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        company: _companyController.text.isEmpty ? null : _companyController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
      );

      final updatedSettings = _settings.copyWith(profile: updatedProfile);
      
      final settingsJson = jsonEncode(updatedSettings.toJson());
      await _secureStorage.write(key: 'user_settings', value: settingsJson);
      
      setState(() {
        _settings = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impostazioni salvate con successo'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvare le impostazioni: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                _buildAISection(),
                const SizedBox(height: 24),
                _buildGitHubSection(),
                const SizedBox(height: 24),
                _buildSecuritySection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
                const SizedBox(height: 100), // Extra space for bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Impostazioni',
        style: TextStyle(
          color: AppColors.titleText(Theme.of(context).brightness),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.save, size: 18),
            label: Text(_isSaving ? 'Salvando...' : 'Salva'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'Profilo Utente',
      icon: Icons.person_outline,
      child: Column(
        children: [
          // Avatar section
          Center(
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _settings.profile.avatarUrl != null
                    ? CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(_settings.profile.avatarUrl!),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'Nome',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bioController,
            label: 'Bio (opzionale)',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _companyController,
            label: 'Azienda (opzionale)',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            label: 'Posizione (opzionale)',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferenze App',
      icon: Icons.tune,
      child: Column(
        children: [
          _buildNewThemeSelector(),
          const SizedBox(height: 16),
          _buildLanguageSelector(),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Feedback aptico',
            subtitle: 'Vibrazione per interazioni',
            value: _settings.preferences.enableHapticFeedback,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  preferences: _settings.preferences.copyWith(enableHapticFeedback: value),
                );
              });
            },
            icon: Icons.vibration,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Animazioni',
            subtitle: 'Abilita animazioni interfaccia',
            value: _settings.preferences.enableAnimations,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  preferences: _settings.preferences.copyWith(enableAnimations: value),
                );
              });
            },
            icon: Icons.animation,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Blur sidebar',
            subtitle: 'Effetto sfocatura dietro sidebar',
            value: _settings.preferences.enableSidebarBlur,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  preferences: _settings.preferences.copyWith(enableSidebarBlur: value),
                );
              });
            },
            icon: Icons.blur_on,
          ),
          const SizedBox(height: 16),
          _buildFontSizeSlider(),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    return _buildSection(
      title: 'Impostazioni AI',
      icon: Icons.smart_toy_outlined,
      child: Column(
        children: [
          _buildModelSelector(),
          const SizedBox(height: 16),
          _buildTemperatureSlider(),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Risposta streaming',
            subtitle: 'Mostra risposta in tempo reale',
            value: _settings.aiSettings.enableStreamResponse,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  aiSettings: _settings.aiSettings.copyWith(enableStreamResponse: value),
                );
              });
            },
            icon: Icons.stream,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Memoria contesto',
            subtitle: 'Ricorda conversazioni precedenti',
            value: _settings.aiSettings.enableContextMemory,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  aiSettings: _settings.aiSettings.copyWith(enableContextMemory: value),
                );
              });
            },
            icon: Icons.memory,
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubSection() {
    return _buildSection(
      title: 'GitHub Integration',
      icon: Icons.code,
      child: Column(
        children: [
          if (_settings.github.accessToken != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Connesso come ${_settings.github.username ?? "utente"}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildActionTile(
            title: _settings.github.accessToken != null ? 'Disconnetti GitHub' : 'Connetti GitHub',
            subtitle: _settings.github.accessToken != null 
              ? 'Rimuovi integrazione GitHub' 
              : 'Connetti il tuo account GitHub',
            icon: _settings.github.accessToken != null ? Icons.link_off : Icons.link,
            onTap: () {
              // TODO: Implementare connessione/disconnessione GitHub
            },
          ),
          if (_settings.github.accessToken != null) ...[
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Auto-sync repository',
              subtitle: 'Sincronizza automaticamente le modifiche',
              value: _settings.github.enableAutoSync,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    github: _settings.github.copyWith(enableAutoSync: value),
                  );
                });
              },
              icon: Icons.sync,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Notifiche',
              subtitle: 'Ricevi notifiche per aggiornamenti',
              value: _settings.github.enableNotifications,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    github: _settings.github.copyWith(enableNotifications: value),
                  );
                });
              },
              icon: Icons.notifications_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Sicurezza',
      icon: Icons.security,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Autenticazione biometrica',
            subtitle: 'Usa Face ID o Touch ID',
            value: _settings.security.enableBiometrics,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  security: _settings.security.copyWith(enableBiometrics: value),
                );
              });
            },
            icon: Icons.fingerprint,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Crittografia dati',
            subtitle: 'Crittografa dati sensibili',
            value: _settings.security.enableDataEncryption,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  security: _settings.security.copyWith(enableDataEncryption: value),
                );
              });
            },
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Permetti screenshot',
            subtitle: 'Consenti cattura schermo dell\'app',
            value: _settings.security.allowScreenshots,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  security: _settings.security.copyWith(allowScreenshots: value),
                );
              });
            },
            icon: Icons.screenshot_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'Informazioni',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildActionTile(
            title: 'Privacy Policy',
            subtitle: 'Visualizza la nostra privacy policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              // TODO: Aprire privacy policy
            },
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Termini di servizio',
            subtitle: 'Leggi i termini di utilizzo',
            icon: Icons.description_outlined,
            onTap: () {
              // TODO: Aprire termini di servizio
            },
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Supporto',
            subtitle: 'Contatta il team di supporto',
            icon: Icons.support_agent_outlined,
            onTap: () {
              // TODO: Aprire supporto
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Drape v1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.titleText(Theme.of(context).brightness)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.bodyText(Theme.of(context).brightness)),
          prefixIcon: Icon(icon, color: AppColors.bodyText(Theme.of(context).brightness)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(Theme.of(context).brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.titleText(Theme.of(context).brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.bodyText(Theme.of(context).brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant(Theme.of(context).brightness).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.titleText(Theme.of(context).brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.bodyText(Theme.of(context).brightness),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.bodyText(Theme.of(context).brightness),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Nuovo selettore tema che usa ThemeProvider
  Widget _buildNewThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themes = [
          {
            'mode': ThemeMode.light, 
            'label': 'Light Mode', 
            'subtitle': 'Tema chiaro per uso diurno',
            'icon': Icons.light_mode_outlined
          },
          {
            'mode': ThemeMode.dark, 
            'label': 'Dark Mode', 
            'subtitle': 'Tema scuro per developer',
            'icon': Icons.dark_mode_outlined
          },
          {
            'mode': ThemeMode.system, 
            'label': 'System', 
            'subtitle': 'Segue le impostazioni del sistema',
            'icon': Icons.brightness_auto_outlined
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VibeCore Theme',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Attuale: ${themeProvider.currentThemeDisplayName}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Lista delle modalità tema
            ...themes.map((theme) {
              final themeMode = theme['mode'] as ThemeMode;
              final isSelected = themeProvider.themeMode == themeMode;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await themeProvider.setThemeMode(themeMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              theme['icon'] as IconData,
                              color: isSelected 
                                ? AppColors.primary
                                : Theme.of(context).iconTheme.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).textTheme.titleMedium?.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  theme['subtitle'] as String,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Indicatore di selezione
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected 
                                  ? AppColors.primary 
                                  : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            
            // Info box sui colori brand
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primaryTint.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.palette,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🟣 Brand Colors',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'I colori viola (#6F5CFF, #B6ADFF, #5946D6) rimangono identici in entrambe le modalità per mantenere la brand consistency.',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    final brightness = Theme.of(context).brightness;
    const languages = [
      {'value': 'it', 'label': 'Italiano', 'flag': '🇮🇹'},
      {'value': 'en', 'label': 'English', 'flag': '🇺🇸'},
      {'value': 'es', 'label': 'Español', 'flag': '🇪🇸'},
      {'value': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.language, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lingua',
                  style: TextStyle(
                    color: AppColors.titleText(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  languages.firstWhere((lang) => lang['value'] == _settings.preferences.language)['label'] as String,
                  style: TextStyle(
                    color: AppColors.bodyText(brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _settings.preferences.language,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface(brightness),
            items: languages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang['value'] as String,
                child: Row(
                  children: [
                    Text(lang['flag'] as String, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      lang['label'] as String,
                      style: TextStyle(color: AppColors.titleText(brightness)),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(
                    preferences: _settings.preferences.copyWith(language: value),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.font_download, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dimensione font',
                      style: TextStyle(
                        color: AppColors.titleText(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_settings.preferences.fontSize.toInt()}px',
                      style: TextStyle(
                        color: AppColors.bodyText(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _settings.preferences.fontSize,
            min: 10,
            max: 24,
            divisions: 14,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  preferences: _settings.preferences.copyWith(fontSize: value),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    final brightness = Theme.of(context).brightness;
    const models = [
      'claude-3-sonnet',
      'claude-3-haiku',
      'gpt-4',
      'gpt-3.5-turbo',
      'gemini-pro',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.psychology, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modello AI predefinito',
                  style: TextStyle(
                    color: AppColors.titleText(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _settings.aiSettings.defaultModel,
                  style: TextStyle(
                    color: AppColors.bodyText(brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _settings.aiSettings.defaultModel,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface(brightness),
            items: models.map((model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(
                  model,
                  style: TextStyle(color: AppColors.titleText(brightness)),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(
                    aiSettings: _settings.aiSettings.copyWith(defaultModel: value),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.thermostat, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperatura AI',
                      style: TextStyle(
                        color: AppColors.titleText(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_settings.aiSettings.temperature.toStringAsFixed(1)} - ${_getTemperatureDescription()}',
                      style: TextStyle(
                        color: AppColors.bodyText(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _settings.aiSettings.temperature,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  aiSettings: _settings.aiSettings.copyWith(temperature: value),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  String _getTemperatureDescription() {
    final temp = _settings.aiSettings.temperature;
    if (temp <= 0.3) return 'Preciso';
    if (temp <= 0.7) return 'Equilibrato';
    return 'Creativo';
  }
}