import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../core/ai/ai_models.dart';
import '../../../../core/ai/ai_manager.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/terminal/terminal_service.dart';
import '../../../../core/terminal/autocomplete_service.dart';
import '../../../../core/terminal/syntax_text_field.dart';
import '../../../../core/github/github_service.dart' as github_service;
import '../../../../core/github/deep_link_handler.dart';
import '../widgets/terminal_syntax_highlighter.dart';
import '../providers/terminal_provider.dart';
import '../widgets/terminal/terminal_input.dart';
import '../widgets/terminal/terminal_output.dart';
import '../widgets/terminal/welcome_view.dart';
import '../widgets/smart_output_card.dart';
import '../widgets/command_card.dart';
import '../../data/models/terminal_item.dart';
import '../../data/models/smart_output_parser.dart';
import 'preview_web_screen.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/data/models/user_settings.dart';
import '../../../create_app/presentation/pages/create_app_wizard_page.dart';

// Terminal item type
enum TerminalItemType {
  command,
  output,
  error,
  system,
}

// Terminal item model
class TerminalItem {
  final String content;
  final TerminalItemType type;
  final DateTime timestamp;

  TerminalItem({
    required this.content,
    required this.type,
    required this.timestamp,
  });
}

// Modello per sessioni di chat
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUsed;
  final List<TerminalItem> messages;
  final String aiModel;
  final String? folderId;
  final String? repositoryId; // ID della repository GitHub associata
  final String? repositoryName; // Nome della repository per display
  
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUsed,
    required this.messages,
    required this.aiModel,
    this.folderId,
    this.repositoryId,
    this.repositoryName,
  });
}

// Modello per cartelle chat
class ChatFolder {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final DateTime createdAt;
  
  ChatFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });
}

// Modello per repository GitHub
class GitHubRepository {
  final String id;
  final String name;
  final String fullName;
  final String? description;
  final String language;
  final bool isPrivate;
  final int stars;
  final int forks;
  final DateTime updatedAt;
  final String cloneUrl;
  final String? avatarUrl;
  
  GitHubRepository({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.language,
    required this.isPrivate,
    required this.stars,
    required this.forks,
    required this.updatedAt,
    required this.cloneUrl,
    this.avatarUrl,
  });
}

// Widget helper per gestire animazioni di pressione
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double pressedScale;
  
  const AnimatedPressButton({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.pressedScale = 0.95,
  });
  
  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    HapticFeedback.lightImpact();
    _controller.reverse();
    widget.onTap();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class WarpTerminalPage extends StatefulWidget {
  const WarpTerminalPage({super.key});

  @override
  State<WarpTerminalPage> createState() => _WarpTerminalPageState();
}

class _WarpTerminalPageState extends State<WarpTerminalPage> with TickerProviderStateMixin {
  late SyntaxHighlightingController _commandController;
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _outputScrollController = ScrollController();
  
  bool _hasInteracted = false;
  bool _isLoading = false;
  List<TerminalItem> _terminalItems = [];
  
  late AnimationController _animationController;
  
  // GitHub Button Animation Controllers
  late AnimationController _gitHubScaleController;
  late AnimationController _gitHubGlowController;
  late AnimationController _gitHubSparkleController;
  late Animation<double> _gitHubScaleAnimation;
  late Animation<double> _gitHubGlowAnimation;
  late Animation<double> _gitHubSparkleAnimation;
  late Animation<Color?> _gitHubColorAnimation;
  bool _isGitHubPressed = false;
  
  // Nuove funzionalità
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  bool _isTerminalMode = true;
  bool _autoApprove = false;
  String _selectedModel = 'auto';
  
  // Timer per il debouncing del riconoscimento automatico
  Timer? _autoDetectDebounce;
  List<File> _attachedImages = [];
  List<File> _taggedFiles = [];
  String? _currentRecordingPath;
  List<ChatSession> _chatHistory = [];
  List<ChatFolder> _chatFolders = [];
  ChatSession? _currentChatSession;
  String? _currentChatTitle;
  
  // GitHub integration
  static const _secureStorage = FlutterSecureStorage();
  final github_service.GitHubService _gitHubService = github_service.GitHubService();
  bool _isGitHubConnected = false;
  bool _isConnectingToGitHub = false;
  String? _gitHubUsername;
  String? _gitHubToken;
  List<github_service.GitHubRepository> _gitHubRepositories = [];
  github_service.GitHubRepository? _selectedRepository;
  github_service.GitHubUser? _gitHubUser;
  
  // Chat search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<ChatSession> _filteredChats = [];
  
  // Autocomplete functionality
  List<AutocompleteOption> _autocompleteOptions = [];
  bool _showAutocomplete = false;
  int _selectedAutocompleteIndex = -1;
  
  // Preview functionality
  String? _previewUrl;
  
  // Expandable tools functionality
  bool _isToolsExpanded = false;
  
  // GitHub sidebar functionality
  bool _showGitHubSidebar = false;
  
  // Sidebar state for blur effect
  bool _isSidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      drawer: _buildSidebar(),
      // AppBar trasparente senza separazione
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isSidebarOpen = isOpened;
        });
      },
      body: Stack(
        children: [
          // Main content che inizia dall'alto (dietro l'AppBar)
          Column(
            children: [
              // Main content area
              Expanded(
                child: _terminalItems.isEmpty && !_isLoading
                    ? _buildWelcomeView(context)
                    : _buildTerminalOutput(),
              ),
              // Input area always at bottom
              _buildInputArea(),
            ],
          ),
          // Blur overlay when sidebar is open
          if (_isSidebarOpen)
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 10.0,
                sigmaY: 10.0,
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final brightness = Theme.of(context).brightness;
    String title = 'Drape';
    String? subtitle;
    
    if (_selectedRepository != null) {
      title = _selectedRepository!.name;
      if (_isGitHubConnected && _gitHubUsername != null) {
        subtitle = '@$_gitHubUsername';
      }
    } 
    else if (_currentChatTitle != null && _currentChatTitle!.isNotEmpty) {
      title = _currentChatTitle!;
    } else if (_currentChatSession != null) {
      title = _currentChatSession!.title;
    } 
    else if (_terminalItems.isNotEmpty) {
      final firstCommand = _terminalItems.firstWhere(
        (item) => item.type == TerminalItemType.command,
        orElse: () => _terminalItems.first,
      );
      title = firstCommand.content.length > 30 
          ? '${firstCommand.content.substring(0, 30)}...'
          : firstCommand.content;
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0, // Rimuove l'elevazione anche durante lo scroll
      surfaceTintColor: Colors.transparent, // Rimuove il tint automatico
      // I controlli galleggiano direttamente sul gradiente della pagina
      leading: Builder(
        builder: (context) => _buildAnimatedSidebarButton(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
                        style: TextStyle(
                          color: AppColors.bodyText(brightness),
                          fontSize: 13,
                        ),
            ),
        ],
      ),
      actions: [
        // Preview button - Minimal design
        if (_previewUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: _openPreview,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Preview',
                      style: TextStyle(
                        color: brightness == Brightness.dark
                            ? const Color(0xFFE5E5E5)
                            : const Color(0xFF1A1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Stop process button - Minimal design
        if (_previewUrl != null && _selectedRepository != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: _stopFlutterProcess,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.stop_circle_outlined,
                  color: AppColors.error.withValues(alpha: 0.8),
                  size: 16,
                ),
              ),
            ),
          ),
        if (_terminalItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _terminalItems.clear();
                  _hasInteracted = false;
                  _previewUrl = null; // Reset preview quando clear
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                          AppColors.surface(Theme.of(context).brightness).withValues(alpha: 0.6),
                          AppColors.surface(Theme.of(context).brightness).withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.clear_all_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
              color: AppColors.surface(Theme.of(context).brightness).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
                color: AppColors.border(Theme.of(context).brightness),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCustomSearchBar() {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
            color: AppColors.surface(Theme.of(context).brightness).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
              color: AppColors.border(Theme.of(context).brightness).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        focusNode: _searchFocusNode,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          suffixIcon: GestureDetector(
            onTap: _startNewChat,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.8), // Indigo soft
                    const Color(0xFF8B5CF6).withValues(alpha: 0.7), // Purple soft
                    const Color(0xFFA855F7).withValues(alpha: 0.6), // Purple light
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          // TODO: Implementare ricerca nelle chat
        },
      ),
    );
  }

  Widget _buildSidebar() {
    final brightness = Theme.of(context).brightness;
    return Drawer(
      backgroundColor: AppColors.surface(brightness),
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            // Top header minimale
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const SizedBox.shrink(), // Header vuoto per ora
            ),
            
            // Search bar custom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _buildCustomSearchBar(),
                  const SizedBox(height: 12),
                  // GitHub - Pulsante animato personalizzato
                  _buildAnimatedGitHubButton(),
                  const SizedBox(height: 8),
                  // Crea App
                  _buildSidebarButton(
                    icon: Icons.rocket_launch_outlined,
                    text: 'Crea App',
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // Chiudi sidebar
                      
                      // Naviga al wizard di creazione app
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => const CreateAppWizardPage(),
                        ),
                      );
                      
                      // Se il progetto è stato creato con successo, potresti voler fare qualcosa
                      if (result == true) {
                        // Il progetto è stato creato con successo
                        // Potresti aggiornare il terminale o fare altre azioni
                      }
                    },
                    isActive: false,
                  ),
                  // Rimosso theme toggle button
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Chat history
            Expanded(
              child: _buildChatHistory(),
            ),
            
            // Bottom section con avatar e user info
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                        color: AppColors.border(Theme.of(context).brightness),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Avatar con gradiente purple - cliccabile per settings
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // chiudi sidebar
                      
                      // Naviga alla pagina delle impostazioni
                      final result = await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                    .chain(CurveTween(curve: Curves.easeInOut)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                      
                      // Se le impostazioni sono state salvate, aggiorna l'UI se necessario
                      if (result != null) {
                        // TODO: Aggiornare UI in base alle nuove impostazioni
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient(brightness),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wlad',
                          style: TextStyle(
                            color: AppColors.titleText(brightness),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Drape Developer',
                          style: TextStyle(
                            color: AppColors.bodyText(brightness),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final themeProvider = context.read<ThemeProvider>();
                      themeProvider.toggleTheme();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        brightness == Brightness.light 
                            ? Icons.dark_mode_outlined 
                            : Icons.light_mode_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
                  ? AppColors.surface(brightness).withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(
            color: AppColors.bodyText(brightness).withValues(alpha: 0.2),
            width: 1,
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive 
                  ? AppColors.titleText(brightness)
                  : AppColors.bodyText(brightness),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: isActive 
                    ? AppColors.titleText(brightness)
                    : AppColors.bodyText(brightness),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeToggleButton() {
    final brightness = Theme.of(context).brightness;
    final themeProvider = context.watch<ThemeProvider>();
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.toggleTheme();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.08),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                brightness == Brightness.light 
                    ? Icons.dark_mode_outlined 
                    : Icons.light_mode_outlined,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brightness == Brightness.light ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: AppColors.titleText(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Switch to ${brightness == Brightness.light ? 'dark' : 'light'} theme',
                    style: TextStyle(
                      color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.toggle_on_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChatHistory() {
    final brightness = Theme.of(context).brightness;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Today section
        if (_getChatsByDate('today').isNotEmpty) ...[
          _buildDateHeader('Today', true),
          const SizedBox(height: 8),
          ..._getChatsByDate('today').map(_buildChatHistoryItem),
          const SizedBox(height: 16),
        ],
        
        // Yesterday section
        if (_getChatsByDate('yesterday').isNotEmpty) ...[
          _buildDateHeader('Yesterday', false),
          const SizedBox(height: 8),
          ..._getChatsByDate('yesterday').map(_buildChatHistoryItem),
          const SizedBox(height: 16),
        ],
        
        // Last 7 days section
        if (_getChatsByDate('week').isNotEmpty) ...[
          _buildDateHeader('Last 7 days', false),
          const SizedBox(height: 8),
          ..._getChatsByDate('week').map(_buildChatHistoryItem),
        ],
      ],
    );
  }
  
  Widget _buildDateHeader(String title, bool isExpanded) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.white70,
          size: 16,
        ),
      ],
    );
  }
  
  Widget _buildChatHistoryItem(ChatSession chat) {
    final isSelected = _currentChatSession?.id == chat.id;
    final isGitHubChat = chat.repositoryId != null;
    
    return InkWell(
      onTap: () => _loadChatSession(chat),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppColors.purpleMedium.withValues(alpha: 0.12),
                    AppColors.violetLight.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(
            color: AppColors.purpleMedium.withValues(alpha: 0.3),
            width: 1.5,
          ) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.purpleMedium.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Indicatore laterale colorato quando selezionato
            if (isSelected)
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 12,
                  vertical: 0,
                ),
                child: Row(
                  children: [
                    // Icona GitHub solo se presente (senza spazio fisso)
                    if (isGitHubChat) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.purpleMedium.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
              
                    // Contenuto chat (inizia sempre dallo stesso punto)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titolo chat
                          Text(
                            chat.title.length > 40 ? '${chat.title.substring(0, 40)}...' : chat.title,
                            style: TextStyle(
                              color: isSelected 
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                          // Nome repository se presente
                          if (isGitHubChat && chat.repositoryName != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  color: AppColors.textTertiary,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    chat.repositoryName!,
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<ChatSession> _getChatsByDate(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    
    return _chatHistory.where((chat) {
      final chatDate = DateTime(chat.lastUsed.year, chat.lastUsed.month, chat.lastUsed.day);
      
      switch (period) {
        case 'today':
          return chatDate.isAtSameMomentAs(today);
        case 'yesterday':
          return chatDate.isAtSameMomentAs(yesterday);
        case 'week':
          return chatDate.isBefore(yesterday) && chatDate.isAfter(weekAgo);
        default:
          return false;
      }
    }).toList();
  }
  
  Widget _buildChatSection() {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Chat Recenti',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._chatHistory.take(5).map((chat) => _buildChatItem(chat)),
        if (_chatHistory.length > 5)
          TextButton(
            onPressed: () {
              // TODO: Show all chats
            },
            child: Text(
              'Vedi tutte (${_chatHistory.length})',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatItem(ChatSession chat) {
    final isSelected = _currentChatSession?.id == chat.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _loadChatSession(chat),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  )
                : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.textTertiary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeAgo(chat.lastUsed),
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chat.aiModel,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubSection() {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'GitHub',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_gitHubRepositories.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_gitHubRepositories.length}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (_isGitHubConnected)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'disconnect') {
                    _disconnectGitHub();
                  } else if (value == 'refresh') {
                    _loadGitHubRepositories();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Ricarica', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Disconnetti', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isGitHubConnected && _gitHubUsername != null) ...[
          // User info - Elegant design
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                  color: AppColors.surface(brightness).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar with subtle ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _gitHubUser?.avatarUrl != null 
                        ? NetworkImage(_gitHubUser!.avatarUrl) 
                        : null,
                    child: _gitHubUser?.avatarUrl == null 
                        ? Text(
                            _gitHubUsername?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 14
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _gitHubUser?.name ?? '@$_gitHubUsername',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Online status indicator
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      if (_gitHubUser?.name != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          '@$_gitHubUsername',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Verified badge with better icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.verified, 
                    color: AppColors.success, 
                    size: 12
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Repositories list
          if (_isConnectingToGitHub)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Caricamento repository...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else if (_gitHubRepositories.isNotEmpty) ...
            _gitHubRepositories.take(5).map((repo) => _buildRepositoryItem(repo)).toList()
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nessuna repository trovata',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          if (_gitHubRepositories.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Show all repositories dialog
              },
              child: Text(
                'Mostra tutte (${_gitHubRepositories.length})',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
        ] else
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isConnectingToGitHub ? null : _connectGitHub,
                icon: _isConnectingToGitHub 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                        ),
                      )
                    : Icon(Icons.link, size: 16),
                label: Text(_isConnectingToGitHub ? 'Connessione...' : 'Connetti GitHub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface(brightness).withValues(alpha: 0.5),
                  foregroundColor: _isConnectingToGitHub ? AppColors.textSecondary : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Debug button for manual testing
              TextButton(
                onPressed: _testOAuthCallback,
                child: Text(
                  'Test OAuth (Debug)',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildRepositoryItem(github_service.GitHubRepository repo) {
    final brightness = Theme.of(context).brightness;
    final isSelected = _selectedRepository?.id == repo.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedRepository = isSelected ? null : repo;
          });
          if (!isSelected) {
            _showSnackBar('📁 Selezionata repository: ${repo.name}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface(brightness).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Icon(
                repo.isPrivate ? Icons.lock : Icons.public,
                size: 14,
                color: repo.isPrivate ? AppColors.primary : AppColors.success,
              ),
              const SizedBox(width: 8),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and language
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            repo.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (repo.language != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getLanguageColor(repo.language!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            repo.language!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Description (if exists)
                    if (repo.description != null && repo.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        repo.description!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Selection indicator and stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (repo.stargazersCount > 0) ...[
                    Icon(Icons.star_outline, size: 10, color: AppColors.textTertiary),
                    const SizedBox(width: 2),
                    Text(
                      '${repo.stargazersCount}',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getLanguageColor(String language) {
    // Use AppColors methods for consistency with theme
    switch (language.toLowerCase()) {
      case 'dart':
        return AppColors.fileTypeColor('.dart');
      case 'javascript':
        return AppColors.fileTypeColor('.js');
      case 'typescript':
        return AppColors.fileTypeColor('.ts');
      case 'python':
        return AppColors.fileTypeColor('.py');
      case 'java':
        return AppColors.fileTypeColor('.java');
      case 'go':
        return AppColors.textSecondary; // Use gray for Go
      case 'rust':
        return AppColors.textPrimary; // Light gray for Rust
      case 'swift':
        return const Color(0xFFFA7343); // Keep orange for Swift
      case 'kotlin':
        return AppColors.primary; // Use theme primary for Kotlin
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildWelcomeView(BuildContext context) {
    return const WelcomeView();
  }

  Widget _buildTerminalOutput() {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        // Attached files/images preview
        if (_attachedImages.isNotEmpty || _taggedFiles.isNotEmpty)
          _buildAttachmentsPreview(),
        // Terminal output
        Expanded(
          child: ListView.builder(
                controller: _outputScrollController,
                itemCount: _terminalItems.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _terminalItems.length && _isLoading) {
                    return _buildModernLoadingIndicator();
                  }
                  
                  final item = _terminalItems[index];
                  return _buildTerminalItem(item);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildTerminalItem(TerminalItem item) {
    // Per i comandi, usa la CommandCard minimal
    if (item.type == TerminalItemType.command) {
      return CommandCard(
        command: item.content,
        timestamp: item.timestamp,
      );
    }
    
    // Per gli output (non comandi), usa le smart cards
    if (item.type == TerminalItemType.output || item.type == TerminalItemType.system) {
      final smartOutput = SmartOutputParser.parse(item.content);
      return SmartOutputCard(
        output: smartOutput,
        onUrlTap: smartOutput.url != null ? () {
          if (smartOutput.url!.startsWith('http')) {
            _previewUrl = smartOutput.url;
            setState(() {});
          }
        } : null,
      );
    }
    
    // Per errori, usa lo stile minimale
    return _buildMinimalTerminalLine(item);
  }
  
  Widget _buildMinimalTerminalLine(TerminalItem item) {
    Color textColor;
    String prefix = '';
    
    switch (item.type) {
      case TerminalItemType.command:
        textColor = const Color(0xFF06B6D4);
        prefix = '❯ ';
        break;
      case TerminalItemType.output:
        textColor = const Color(0xFFE2E8F0);
        prefix = '';
        break;
      case TerminalItemType.error:
        textColor = const Color(0xFFEF4444);
        prefix = '✗ ';
        break;
      case TerminalItemType.system:
        textColor = const Color(0xFF10B981);
        prefix = '✓ ';
        break;
      default:
        textColor = const Color(0xFF9CA3AF);
        prefix = '';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix.isNotEmpty)
            Text(
              prefix,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Mono',
              ),
            ),
          Expanded(
            child: _buildContent(item, textColor),
          ),
          if (item.type == TerminalItemType.command)
            Text(
              _formatTime(item.timestamp),
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontFamily: 'SF Mono',
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildContent(TerminalItem item, Color textColor) {
    if (item.type == TerminalItemType.command && _isTerminalMode) {
      return SelectableText.rich(
        TextSpan(
          children: TerminalSyntaxHighlighter.highlightCommand(
            item.content,
            textColor,
          ),
        ),
      );
    }
    
    if (item.type == TerminalItemType.output) {
      // Check for special Flutter output
      if (item.content.contains('Flutter web app') || 
          item.content.contains('http://')) {
        return _buildFlutterOutput(item.content);
      }
      
      return SelectableText.rich(
        TextSpan(
          children: TerminalSyntaxHighlighter.highlightOutput(
            item.content,
            textColor,
          ),
        ),
      );
    }
    
    return SelectableText(
      item.content,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontFamily: 'SF Mono',
        height: 1.4,
      ),
    );
  }
  
  Widget _buildFlutterOutput(String content) {
    RegExp urlRegex = RegExp(r'https?://[^\\s]+');
    Match? urlMatch = urlRegex.firstMatch(content);
    String? url = urlMatch?.group(0);
    
    if (url != null) {
      // Split content to highlight URL
      List<String> parts = content.split(url);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parts[0].isNotEmpty)
            SelectableText(
              parts[0],
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14,
                fontFamily: 'SF Mono',
                height: 1.4,
              ),
            ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              _showSnackBar('✅ URL copiato negli appunti');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: Color(0xFF06B6D4),
                        fontSize: 13,
                        fontFamily: 'SF Mono',
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF06B6D4),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          if (parts.length > 1 && parts[1].isNotEmpty)
            SelectableText(
              parts[1],
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14,
                fontFamily: 'SF Mono',
                height: 1.4,
              ),
            ),
        ],
      );
    }
    
    return SelectableText(
      content,
      style: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 14,
        fontFamily: 'SF Mono',
        height: 1.4,
      ),
    );
  }
  
  Widget _buildCommandCard(TerminalItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3748),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C51BF), Color(0xFF667EEA)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comando eseguito',
                  style: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText.rich(
                  TextSpan(
                    children: _isTerminalMode
                      ? TerminalSyntaxHighlighter.highlightCommand(
                          item.content,
                          const Color(0xFFE2E8F0),
                        )
                      : [TextSpan(
                          text: item.content,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontFamily: 'SF Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_formatTime(item.timestamp)}',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOutputCard(TerminalItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF06B6D4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Output',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormattedOutput(item.content),
        ],
      ),
    );
  }
  
  Widget _buildFormattedOutput(String content) {
    // Controlla se è un output di Flutter
    if (content.contains('Flutter web app') || content.contains('http://')) {
      return _buildFlutterOutputCard(content);
    }
    
    // Controlla se è un output di successo
    if (content.toLowerCase().contains('success') || 
        content.contains('✅') || 
        content.contains('✓')) {
      return _buildSuccessOutputCard(content);
    }
    
    // Output normale
    return _buildNormalOutputCard(content);
  }
  
  Widget _buildFlutterOutputCard(String content) {
    // Estrae l'URL se presente
    RegExp urlRegex = RegExp(r'https?://[^\s]+');
    Match? urlMatch = urlRegex.firstMatch(content);
    String? url = urlMatch?.group(0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF1D4ED8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Flutter App Avviata',
                style: TextStyle(
                  color: const Color(0xFF3B82F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (url != null) 
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: Color(0xFF06B6D4),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(
                        color: Color(0xFF06B6D4),
                        fontFamily: 'SF Mono',
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copia URL negli appunti
                      Clipboard.setData(ClipboardData(text: url));
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF64748B),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          if (url != null) const SizedBox(height: 8),
          SelectableText.rich(
            TextSpan(
              children: TerminalSyntaxHighlighter.highlightOutput(
                content,
                const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessOutputCard(String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              content,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNormalOutputCard(String content) {
    return SelectableText.rich(
      TextSpan(
        children: TerminalSyntaxHighlighter.highlightOutput(
          content,
          const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
  
  Widget _buildErrorCard(TerminalItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.1),
            const Color(0xFFDC2626).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Errore',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  item.content,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 13,
                    fontFamily: 'SF Mono',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemCard(TerminalItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              item.content,
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultCard(TerminalItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        item.content,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 13,
          fontFamily: 'SF Mono',
          height: 1.4,
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildModernLoadingIndicator() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Pensando',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontFamily: 'SF Mono',
                    height: 1.4,
                  ),
                ),
                _buildMinimalAnimatedDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMinimalAnimatedDots() {
    final brightness = Theme.of(context).brightness;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            double delay = index * 0.3;
            double animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
            double opacity = (sin(animationValue * pi * 2) + 1) / 2;
            
            return Text(
              '.',
              style: TextStyle(
                color: const Color(0xFF64748B).withOpacity(opacity),
                fontSize: 20,
                fontFamily: 'SF Mono',
                height: 1,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAttachmentsPreview() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border(brightness).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachedImages.isNotEmpty) ...[
            Text(
              'Immagini (${_attachedImages.length})',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length,
                itemBuilder: (context, index) {
                  final image = _attachedImages[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(image),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (_taggedFiles.isNotEmpty) ...[
            if (_attachedImages.isNotEmpty) const SizedBox(height: 12),
            Text(
              'File Taggati (${_taggedFiles.length})',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _taggedFiles.map((file) {
                final fileName = file.path.split('/').last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description,
                        color: AppColors.primary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fileName.length > 20 
                            ? '${fileName.substring(0, 20)}...'
                            : fileName,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeTaggedFile(file),
                        child: Icon(
                          Icons.close,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final brightness = Theme.of(context).brightness;
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface(brightness).withValues(alpha: 0.98),
                  AppColors.surface(brightness).withValues(alpha: 0.92),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.purpleMedium.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.purpleMedium.withValues(alpha: 0.12),
                  blurRadius: 50,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Advanced controls - Top section unificata
                Container(
                  height: 40, // Altezza unificata per tutti
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Toggle Terminal/AI con logica auto
                      _buildSmartModeToggle(),
                      const Spacer(),
                      // Model selector - sempre a destra
                      _buildUnifiedModelSelector(),
                    ],
                  ),
                ),
                // Main input row unificata
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Tools button
                      _buildUnifiedToolsButton(),
                      const SizedBox(width: 12),
                      // Command input
                      Expanded(
                        child: SyntaxTextField(
                          controller: _commandController,
                          focusNode: _commandFocusNode,
                          maxLines: null,
                          constraints: const BoxConstraints(maxHeight: 120),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontFamily: 'SF Mono',
                              height: 1.4,
                            ),
                            hintText: _getSmartHintText(),
                            hintStyle: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 14,
                              ),
                              isDense: false,
                            ),
                            onChanged: _onSmartInputChanged,
                            onSubmitted: _executeCommand,
                          ),
                      ),
                      const SizedBox(width: 12),
                      // Send button unificato
                      _buildUnifiedSendButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Autocomplete overlay
        if (_showAutocomplete && _autocompleteOptions.isNotEmpty)
          _buildAutocompleteOverlay(),
      ],
    );
  }

  // Sistema intelligente per riconoscere Agent vs Terminal
  bool _isAgentQuery(String text) {
    final lowerText = text.toLowerCase().trim();
    
    // Non fare riconoscimento per testi troppo corti o vuoti
    if (lowerText.length < 2) {
      return !_isTerminalMode; // Mantieni la modalità attuale
    }
    
    // Pattern espliciti per Terminal (priorità alta)
    final terminalPatterns = [
      'ls', 'cd', 'pwd', 'mkdir', 'rm', 'cp', 'mv',
      'git', 'npm', 'yarn', 'pnpm', 'node', 'python',
      'flutter run', 'flutter build', 'flutter test',
      'docker', 'kubectl', 'ssh', 'curl', 'wget',
      'java', 'go run', 'cmake', 'make', 'gcc', 'clang',
      'cat', 'grep', 'find', 'ps', 'kill', 'top',
      'chmod', 'chown', 'tar', 'zip', 'unzip',
    ];
    
    // Se inizia con un comando terminal noto (priorità massima)
    for (final pattern in terminalPatterns) {
      if (lowerText.startsWith(pattern)) {
        return false; // È decisamente terminal
      }
    }
    
    // Pattern espliciti per Agent/AI (solo parole chiave forti)
    final agentPatterns = [
      'ciao', 'hello', 'hi', 'aiuto', 'help',
      'come posso', 'how can', 'spiegami', 'explain',
      'cosa significa', 'what does', 'what is',
      'perché', 'perchè', 'why',
      'crea un', 'create a', 'genera',
      'puoi aiutarmi', 'can you help',
      'mostrami', 'show me',
    ];
    
    // Controlla pattern agent solo se è abbastanza lungo
    if (lowerText.length >= 5) {
      for (final pattern in agentPatterns) {
        if (lowerText.contains(pattern)) {
          return true; // È agent
        }
      }
    }
    
    // Domande esplicite (solo se hanno punto interrogativo E sono abbastanza lunghe)
    if (lowerText.contains('?') && lowerText.length >= 8) {
      return true;
    }
    
    // Frasi lunghe e descrittive (probabilmente domande all'AI)
    if (lowerText.split(' ').length >= 5 && lowerText.length >= 20) {
      return true;
    }
    
    // Default: mantieni la modalità attuale per evitare cambi frequenti
    return !_isTerminalMode;
  }
  
  String _getSmartHintText() {
    return _isTerminalMode 
        ? 'Scrivi un comando...'
        : 'Chiedi qualcosa all\'AI...';
  }
  
  void _onSmartInputChanged(String text) {
    // Riconoscimento automatico solo se la modalità AUTO è abilitata
    if (_isAutoModeEnabled) {
      // Cancella il timer precedente se esiste
      _autoDetectDebounce?.cancel();
      
      // Imposta un nuovo timer con debouncing di 300ms
      _autoDetectDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _isAutoModeEnabled) {
          bool shouldBeAgent = _isAgentQuery(text);
          
          if (shouldBeAgent != !_isTerminalMode) {
            setState(() {
              _isTerminalMode = !shouldBeAgent;
            });
            // Update syntax highlighting controller solo se necessario
            _updateSyntaxController();
          }
        }
      });
    }
    
    // Chiama la funzione originale
    _onInputChanged(text);
  }
  
  // DESIGN SYSTEM SOFT E OUTLINED - Minimalista
  static const double _buttonHeight = 36.0;
  static const double _buttonWidth = 32.0;
  static const double _borderRadius = 18.0;
  static const double _borderWidth = 1.0;
  static const Duration _animationDuration = Duration(milliseconds: 200);
  
  // Colori soft e minimalisti - Palette violacea
  static const Color _backgroundSoft = Color(0xFF1A1A1A); // Sfondo molto scuro
  static const Color _borderDefault = Color(0xFF2A2A2A);   // Bordo soft grigio
  static const Color _borderActive = Color(0xFF3A3A3A);    // Bordo attivo più chiaro
  static const Color _borderPurple = Color(0xFF8B7CF6);    // Viola vivace ma elegante per elementi attivi
  static const Color _textPrimary = Color(0xFFF0F0F0);     // Testo bianco soft
  static const Color _textSecondary = Color(0xFF8A8A8A);   // Testo grigio
  static const Color _textPurple = Color(0xFF9B8DF3);      // Testo viola vivace ma elegante per attivi
  static const Color _fillSoft = Color(0xFF0F0F0F);        // Fill molto sottile
  static const Color _activeColor = Color(0xFF8B7CF6);     // Colore per stati attivi
  static const Color _activeIconColor = Color(0xFFFFFFFF); // Colore icone attive
  static const Color _inactiveIconColor = Color(0xFF8A8A8A); // Colore icone inattive
  
  // Stato della modalità - inizialmente in auto (nessun pulsante selezionato)
  bool _isAutoModeEnabled = true; // Modalità automatica attiva
  bool _manualModeSelected = false; // Nessuna modalità manualmente selezionata inizialmente
  
  Widget _buildSmartModeToggle() {
    final brightness = Theme.of(context).brightness;
    // Determina se siamo in modalità manuale per le animazioni del contenitore
    final bool hasManualSelection = _manualModeSelected;
    final bool hasAnyHighlight = (_manualModeSelected && _isTerminalMode) || 
                                 (_manualModeSelected && !_isTerminalMode) ||
                                 (!_manualModeSelected && _isTerminalMode) ||
                                 (!_manualModeSelected && !_isTerminalMode);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      height: _buttonHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: hasManualSelection 
            ? _borderPurple.withValues(alpha: 0.4) 
            : _borderDefault,
          width: _borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: hasManualSelection 
              ? _borderPurple.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.1),
            blurRadius: hasManualSelection ? 8 : 4,
            offset: Offset(0, hasManualSelection ? 2 : 1),
            spreadRadius: hasManualSelection ? 1 : 0,
          ),
        ],
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: hasAnyHighlight ? 1.02 : 1.0,
        curve: Curves.elasticOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmartModeButton(
              icon: Icons.terminal_rounded,
              isActive: _manualModeSelected && _isTerminalMode,
              isAuto: !_manualModeSelected && _isTerminalMode,
              onTap: () {
                setState(() {
                  if (_manualModeSelected && _isTerminalMode) {
                    // Se è già selezionato Terminal, torna in auto
                    _manualModeSelected = false;
                    _isAutoModeEnabled = true;
                  } else {
                    // Seleziona Terminal manualmente
                    _manualModeSelected = true;
                    _isAutoModeEnabled = false;
                    _isTerminalMode = true;
                  }
                });
                _updateSyntaxController();
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: hasManualSelection ? 4 : 2,
            ),
            _buildSmartModeButton(
              icon: Icons.auto_awesome_rounded,
              isActive: _manualModeSelected && !_isTerminalMode,
              isAuto: !_manualModeSelected && !_isTerminalMode,
              onTap: () {
                setState(() {
                  if (_manualModeSelected && !_isTerminalMode) {
                    // Se è già selezionato AI, torna in auto
                    _manualModeSelected = false;
                    _isAutoModeEnabled = true;
                  } else {
                    // Seleziona AI manualmente
                    _manualModeSelected = true;
                    _isAutoModeEnabled = false;
                    _isTerminalMode = false;
                  }
                });
                _updateSyntaxController();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmartModeButton({
    required IconData icon,
    required bool isActive,
    required bool isAuto,
    required VoidCallback onTap,
  }) {
    final bool isHighlighted = isActive || isAuto;
    
    return AnimatedPressButton(
      pressedScale: 0.92,
      duration: const Duration(milliseconds: 120),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: _buttonHeight - 6,
        width: _buttonWidth,
        decoration: BoxDecoration(
          color: isActive 
            ? _activeColor  // Colore pieno per modalità manuale selezionata
            : isAuto
              ? _activeColor.withValues(alpha: 0.3)  // Colore attenuato per modalità auto
              : Colors.transparent,  // Trasparente per modalità non attive
          borderRadius: BorderRadius.circular(_borderRadius - 3),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: _activeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: _activeColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : isAuto
              ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 280),
            scale: isHighlighted ? 1.0 : 0.88,
            curve: Curves.elasticOut,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              turns: isActive ? 0.015 : 0.0, // Leggera rotazione quando manualmente attivo
              curve: Curves.easeInOutBack,
              child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_borderRadius - 5),
                gradient: isActive
                  ? RadialGradient(
                      colors: [
                        _activeColor.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    )
                  : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey('${icon.codePoint}_${isActive}_${isAuto}'),
                  color: isHighlighted
                    ? (isActive ? _activeIconColor : _activeIconColor.withValues(alpha: 0.85))
                    : _inactiveIconColor,
                  size: isHighlighted ? (isActive ? 19 : 17) : 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnifiedModelSelector() {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: _showBeautifulModelSelector,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: _borderDefault,
            width: _borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSelectedModelDisplayName().split(' ').first,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondary,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnifiedToolsButton() {
    final brightness = Theme.of(context).brightness;
    final bool hasActiveTools = _attachedImages.isNotEmpty || 
                               _taggedFiles.isNotEmpty || 
                               _isRecording || 
                               _currentRecordingPath != null ||
                               _autoApprove;
    
    return GestureDetector(
      onTap: _showToolsBottomSheet,
      child: AnimatedContainer(
        duration: _animationDuration,
        width: _buttonHeight,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: hasActiveTools ? _fillSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: hasActiveTools ? _borderPurple : _borderDefault,
            width: _borderWidth,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: hasActiveTools ? _textPurple : _textSecondary,
              size: 16,
            ),
            if (hasActiveTools)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _borderPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnifiedSendButton() {
    final brightness = Theme.of(context).brightness;
    final bool hasText = _commandController.text.trim().isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        if (hasText) {
          _executeCommand(_commandController.text);
        }
      },
      child: AnimatedContainer(
        duration: _animationDuration,
        width: _buttonHeight,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: hasText ? _fillSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: hasText ? _borderPurple : _borderDefault,
            width: _borderWidth,
          ),
        ),
        child: AnimatedScale(
          duration: _animationDuration,
          scale: hasText ? 1.0 : 0.95,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: hasText ? _textPurple : _textSecondary,
            size: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isPurple = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
            ? LinearGradient(
                colors: isPurple 
                  ? [
                      const Color(0xFF4A4458), // Viola molto scuro e desaturato
                      const Color(0xFF3A3446), // Ancora più scuro
                    ]
                  : [
                      const Color(0xFF404552), // Blu-grigio scuro  
                      const Color(0xFF323642), // Più scuro
                    ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: isPurple 
                    ? const Color(0xFF4A4458).withValues(alpha: 0.15)
                    : const Color(0xFF404552).withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.1 : 1.0,
              child: Icon(
                icon,
                color: isActive
                  ? Colors.white
                  : AppColors.textSecondary.withValues(alpha: 0.7),
                size: 12,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive
                  ? Colors.white
                  : AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isActive ? 0.2 : 0.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateSyntaxController() {
    // Solo ricreare il controller se la modalità è effettivamente cambiata
    if (_commandController.isTerminalMode != _isTerminalMode) {
      String currentText = _commandController.text;
      int currentSelection = _commandController.selection.baseOffset;
      
      _commandController.removeListener(() {
        setState(() {});
      });
      _commandController.dispose();
      
      _commandController = SyntaxHighlightingController(
        defaultTextColor: AppColors.textPrimary,
        isTerminalMode: _isTerminalMode,
        text: currentText,
      );
      
      _commandController.addListener(() {
        setState(() {});
      });
      
      // Ripristina la posizione del cursore se possibile
      if (currentSelection >= 0 && currentSelection <= currentText.length) {
        _commandController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentSelection),
        );
      }
    }
  }
  
  Widget _buildCompactModelSelector() {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: _showBeautifulModelSelector,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D3748), // Grigio scuro con sfumatura blu
              const Color(0xFF1A202C), // Più scuro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4A5568).withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A202C).withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withValues(alpha: 0.8), // Blu sottile
                    const Color(0xFF764BA2).withValues(alpha: 0.8), // Viola sottile
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getSelectedModelDisplayName().split(' ').first,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.expand_more_rounded,
                color: Color(0xFFA0AEC0),
                size: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactInputTools() {
    final brightness = Theme.of(context).brightness;
    final bool hasActiveTools = _attachedImages.isNotEmpty || 
                               _taggedFiles.isNotEmpty || 
                               _isRecording || 
                               _currentRecordingPath != null ||
                               _autoApprove;
    
    return GestureDetector(
      onTap: _showToolsBottomSheet,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: hasActiveTools
              ? AppColors.purpleGradient
              : LinearGradient(
                  colors: [
                    AppColors.surface(brightness).withValues(alpha: 0.8),
                    AppColors.surface(brightness).withValues(alpha: 0.6),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(brightness).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: hasActiveTools
              ? [
                  BoxShadow(
                    color: AppColors.purpleMedium.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: hasActiveTools
                  ? Colors.white
                  : AppColors.textSecondary,
              size: 16,
            ),
            if (hasActiveTools)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showToolsBottomSheet() {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.purpleMedium.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Text(
              'Aggiungi contenuti',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Tools grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolTile(
                  icon: Icons.image_outlined,
                  label: 'Foto',
                  isActive: _attachedImages.isNotEmpty,
                  badge: _attachedImages.isNotEmpty ? _attachedImages.length : null,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                _buildToolTile(
                  icon: Icons.attach_file_outlined,
                  label: 'File',
                  isActive: _taggedFiles.isNotEmpty,
                  badge: _taggedFiles.isNotEmpty ? _taggedFiles.length : null,
                  onTap: () {
                    Navigator.pop(context);
                    _selectFilesToTag();
                  },
                ),
                _buildToolTile(
                  icon: _isRecording ? Icons.stop : Icons.mic_outlined,
                  label: _isRecording ? 'Stop' : 'Audio',
                  isActive: _isRecording || _currentRecordingPath != null,
                  isRecording: _isRecording,
                  onTap: () {
                    Navigator.pop(context);
                    _toggleRecording();
                  },
                ),
                _buildToolTile(
                  icon: Icons.auto_mode_outlined,
                  label: 'Auto',
                  isActive: _autoApprove,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _autoApprove = !_autoApprove;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToolTile({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int? badge,
    bool isRecording = false,
  }) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
            ? AppColors.purpleGradient
            : LinearGradient(
                colors: [
                  AppColors.surface(brightness).withValues(alpha: 0.4),
                  AppColors.surface(brightness).withValues(alpha: 0.2),
                ],
              ),
          borderRadius: BorderRadius.circular(16),
          border: isRecording
            ? Border.all(
                color: Colors.red.withValues(alpha: 0.7),
                width: 2,
              )
            : Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.1),
                width: 1,
              ),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.purpleMedium.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildMiniToolButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    int? badge,
    bool isRecording = false,
  }) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: isActive
                ? AppColors.heroGradient(brightness)
                : LinearGradient(
                    colors: [
                      AppColors.surface(brightness).withValues(alpha: 0.4),
                      AppColors.surface(brightness).withValues(alpha: 0.2),
                    ],
                  ),
              borderRadius: BorderRadius.circular(11),
              border: isRecording
                ? Border.all(
                    color: Colors.red.withValues(alpha: 0.7),
                    width: 1,
                  )
                : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 11,
            ),
          ),
          if (badge != null)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                constraints: const BoxConstraints(minWidth: 12),
                height: 12,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildModeToggle() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terminal mode
          GestureDetector(
            onTap: () {
              if (!_isTerminalMode) {
                setState(() {
                  _isTerminalMode = true;
                });
                // Update syntax highlighting controller
                String currentText = _commandController.text;
                _commandController.dispose();
                _commandController = SyntaxHighlightingController(
                  defaultTextColor: AppColors.textPrimary,
                  isTerminalMode: _isTerminalMode,
                  text: currentText,
                );
                _commandController.addListener(() {
                  setState(() {});
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: _isTerminalMode
                  ? AppColors.heroGradient(brightness)
                  : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isTerminalMode
                  ? [
                      BoxShadow(
                        color: AppColors.violetLight.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.terminal,
                    color: _isTerminalMode
                      ? Colors.white
                      : AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terminal',
                    style: TextStyle(
                      color: _isTerminalMode
                        ? Colors.white
                        : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Agent mode
          GestureDetector(
            onTap: () {
              if (_isTerminalMode) {
                setState(() {
                  _isTerminalMode = false;
                });
                // Update syntax highlighting controller
                String currentText = _commandController.text;
                _commandController.dispose();
                _commandController = SyntaxHighlightingController(
                  defaultTextColor: AppColors.textPrimary,
                  isTerminalMode: _isTerminalMode,
                  text: currentText,
                );
                _commandController.addListener(() {
                  setState(() {});
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: !_isTerminalMode
                  ? AppColors.purpleGradient
                  : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: !_isTerminalMode
                  ? [
                      BoxShadow(
                        color: AppColors.purpleMedium.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: !_isTerminalMode
                      ? Colors.white
                      : AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Agent',
                    style: TextStyle(
                      color: !_isTerminalMode
                        ? Colors.white
                        : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTools() {
    final brightness = Theme.of(context).brightness;
    // Calculate if any tool is active
    final bool hasActiveTools = _attachedImages.isNotEmpty || 
                               _taggedFiles.isNotEmpty || 
                               _isRecording || 
                               _currentRecordingPath != null ||
                               _autoApprove;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: Row(
        children: [
          // Main expandable button
          GestureDetector(
            onTap: () {
              setState(() {
                _isToolsExpanded = !_isToolsExpanded;
              });
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: hasActiveTools || _isToolsExpanded
                    ? AppColors.purpleGradient
                    : LinearGradient(
                        colors: [
                          AppColors.surface(brightness).withValues(alpha: 0.6),
                          AppColors.surface(brightness).withValues(alpha: 0.4),
                        ],
                      ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: _isToolsExpanded 
                      ? AppColors.purpleMedium.withValues(alpha: 0.4)
                      : AppColors.border(brightness).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: hasActiveTools || _isToolsExpanded
                    ? [
                        BoxShadow(
                          color: AppColors.purpleMedium.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main icon
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isToolsExpanded ? 0.125 : 0.0, // 45 degrees
                    child: Icon(
                      Icons.add_rounded,
                      color: hasActiveTools || _isToolsExpanded
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  // Badge indicator for active tools
                  if (hasActiveTools && !_isToolsExpanded)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Expanded tools
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isToolsExpanded ? 160 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isToolsExpanded ? 1.0 : 0.0,
              child: _isToolsExpanded 
                  ? Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          // Images
                          _buildCompactToolButton(
                            icon: Icons.image_outlined,
                            isActive: _attachedImages.isNotEmpty,
                            onTap: _pickImages,
                            badge: _attachedImages.length > 0 ? _attachedImages.length : null,
                          ),
                          const SizedBox(width: 6),
                          // Files
                          _buildCompactToolButton(
                            icon: Icons.attach_file_outlined,
                            isActive: _taggedFiles.isNotEmpty,
                            onTap: _selectFilesToTag,
                            badge: _taggedFiles.length > 0 ? _taggedFiles.length : null,
                          ),
                          const SizedBox(width: 6),
                          // Audio recording
                          _buildCompactToolButton(
                            icon: _isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined,
                            isActive: _isRecording || _currentRecordingPath != null,
                            onTap: _toggleRecording,
                            isRecording: _isRecording,
                          ),
                          const SizedBox(width: 6),
                          // Auto approve
                          _buildCompactToolButton(
                            icon: Icons.auto_mode_outlined,
                            isActive: _autoApprove,
                            onTap: () {
                              setState(() {
                                _autoApprove = !_autoApprove;
                              });
                              _showSnackBar(_autoApprove 
                                  ? 'Auto-approvazione attivata'
                                  : 'Auto-approvazione disattivata');
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    int? badge,
    bool isRecording = false,
  }) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: isActive
                ? AppColors.heroGradient(brightness)
                : LinearGradient(
                    colors: [
                      AppColors.surface(brightness).withValues(alpha: 0.4),
                      AppColors.surface(brightness).withValues(alpha: 0.2),
                    ],
                  ),
              borderRadius: BorderRadius.circular(14),
              border: isRecording
                ? Border.all(
                    color: Colors.red.withValues(alpha: 0.7),
                    width: 1.5,
                  )
                : null,
              boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.violetLight.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 14,
            ),
          ),
          // Badge for count
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14),
                height: 14,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: _showBeautifulModelSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.aiGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              _getSelectedModelDisplayName().split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // Implementazione dei metodi...
  @override
  void initState() {
    super.initState();
    
    _commandController = SyntaxHighlightingController(
      defaultTextColor: AppColors.textPrimary,
      isTerminalMode: _isTerminalMode,
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialize GitHub button animations
    _gitHubScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _gitHubGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _gitHubSparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _gitHubScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _gitHubScaleController,
      curve: Curves.easeInOut,
    ));
    
    _gitHubGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gitHubGlowController,
      curve: Curves.easeInOut,
    ));
    
    _gitHubSparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gitHubSparkleController,
      curve: Curves.elasticOut,
    ));
    
    _gitHubColorAnimation = ColorTween(
      begin: AppColors.textSecondary,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _gitHubGlowController,
      curve: Curves.easeInOut,
    ));
    
    _commandFocusNode.addListener(_onFocusChange);
    _commandFocusNode.addListener(() {
      if (!_commandFocusNode.hasFocus) {
        setState(() {
          _showAutocomplete = false;
        });
      }
    });
    _commandController.addListener(() {
      setState(() {});
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _updateFilteredChats();
      });
    });
    
    _initializeSampleChats();
    _loadGitHubCredentials();
    _initializeTerminal();
    _setupTerminalOutputListener();
    _initializeDeepLinkHandler();
  }
  
  @override
  void dispose() {
    _autoDetectDebounce?.cancel();
    _commandController.dispose();
    _commandFocusNode.dispose();
    _outputScrollController.dispose();
    _animationController.dispose();
    _gitHubScaleController.dispose();
    _gitHubGlowController.dispose();
    _gitHubSparkleController.dispose();
    _audioRecorder.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_commandFocusNode.hasFocus && !_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
      _animationController.forward();
    }
  }

  void _executeCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }
    
    setState(() {
      _terminalItems.add(
        TerminalItem(
          content: _isTerminalMode ? '${TerminalService().getPrompt()}$command' : command,
          type: TerminalItemType.command,
          timestamp: DateTime.now(),
        )
      );
      _isLoading = true;
      
      if (_currentChatTitle == null && _terminalItems.length == 1) {
        _currentChatTitle = command.length > 30 
          ? '${command.substring(0, 30)}...'
          : command;
      }
    });
    
    try {
      if (_isTerminalMode) {
        // Set repository context before executing command
        TerminalService().setCurrentRepository(_selectedRepository?.name);
        
        // Execute real terminal command
        final result = await TerminalService().executeCommand(command);
        
        if (result.isClearCommand) {
          setState(() {
            _terminalItems.clear();
            _previewUrl = null; // Reset preview when clearing
            _isLoading = false;
          });
        } else {
          setState(() {
            if (result.output.isNotEmpty) {
              _terminalItems.add(
                TerminalItem(
                  content: result.output,
                  type: result.isSuccess ? TerminalItemType.output : TerminalItemType.error,
                  timestamp: DateTime.now(),
                )
              );
            }
            
            // Check for web server from TerminalService (Docker backend)
            _updatePreviewFromTerminalService();
            
            // Fallback: check output for patterns (local mode)
            if (_previewUrl == null) {
              _checkForRunningApp(result.output);
            }
            
            _isLoading = false;
          });
        }
      } else {
        // Execute AI command - usa selezione automatica se necessario
        final actualModel = _selectedModel == 'auto' 
          ? _getAutoSelectedModel(command)
          : _selectedModel;
        await AIManager.instance.switchModel(actualModel);
        
        final context = CodeContext(
          currentFile: _selectedRepository?.name,
          language: 'dart',
        );
        
        final conversationHistory = <String>[];
        for (int i = 0; i < _terminalItems.length - 1; i++) {
          conversationHistory.add(_terminalItems[i].content);
        }
        
        final aiResponse = await AIManager.instance.chat(
          command,
          conversationHistory,
          context: context,
        );
        
        setState(() {
          _terminalItems.add(
            TerminalItem(
              content: aiResponse.content,
              type: TerminalItemType.output,
              timestamp: DateTime.now(),
            )
          );
          // Check if AI response mentions running app
          _checkForRunningApp(aiResponse.content);
          _isLoading = false;
        });
      }
      
    } catch (e) {
      String fallbackResponse = _isTerminalMode 
        ? 'Command failed: $e'
        : _generateFallbackResponse(command, e.toString());
      
      setState(() {
        _terminalItems.add(
          TerminalItem(
            content: fallbackResponse,
            type: TerminalItemType.error,
            timestamp: DateTime.now(),
          )
        );
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
    _commandController.clear();
    
    if (_terminalItems.length >= 2) {
      _saveChatSession();
    }
  }

  String _generateFallbackResponse(String command, String error) {
    final buffer = StringBuffer();
    buffer.writeln('⚠️ Servizio AI temporaneamente non disponibile');
    buffer.writeln();
    
    if (command.toLowerCase().contains('crea') || command.toLowerCase().contains('nuovo')) {
      buffer.writeln('Per creare un nuovo progetto Flutter:');
      buffer.writeln('1. Usa il comando: flutter create nome_progetto');
      buffer.writeln('2. Naviga nella directory: cd nome_progetto');
      buffer.writeln('3. Avvia il progetto: flutter run');
    } else if (command.toLowerCase().contains('test') || command.toLowerCase().contains('esegui')) {
      buffer.writeln('Per eseguire i test:');
      buffer.writeln('• flutter test - Esegue tutti i test');
      buffer.writeln('• flutter test --coverage - Con coverage');
      buffer.writeln('• flutter test integration_test/ - Test di integrazione');
    } else if (command.toLowerCase().contains('aiuto') || command.toLowerCase().contains('help')) {
      buffer.writeln('Comandi disponibili:');
      buffer.writeln('• "Crea un nuovo progetto Flutter"');
      buffer.writeln('• "Esegui i test del progetto corrente"');
      buffer.writeln('• "Analizza il codice del progetto"');
      buffer.writeln('• "Aiuto" - Mostra questa guida');
    } else {
      buffer.writeln('Non sono riuscito a elaborare la richiesta.');
      buffer.writeln('Riprova più tardi quando il servizio AI sarà disponibile.');
    }
    
    buffer.writeln();
    buffer.writeln('Errore tecnico: ${error.length > 100 ? error.substring(0, 100) + "..." : error}');
    
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_outputScrollController.hasClients) {
        _outputScrollController.animateTo(
          _outputScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getSelectedModelDisplayName() {
    if (_selectedModel == 'auto') {
      return 'Auto';
    }
    
    final model = AIModel.allModels.firstWhere(
      (m) => m.id == _selectedModel,
      orElse: () => AIModel.allModels.first,
    );
    return model.displayName;
  }
  
  Widget _buildAutoModelOption(bool isSelected) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedModel = 'auto';
            });
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  )
                : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  )
                : Border.all(
                    color: AppColors.border(brightness).withValues(alpha: 0.1),
                    width: 1,
                  ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                        ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
                        : [AppColors.textTertiary.withValues(alpha: 0.2), AppColors.textTertiary.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Auto (Consigliato)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SMART',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seleziona automaticamente il modello migliore per ogni richiesta',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getAutoSelectedModel(String userInput) {
    // Logica intelligente per selezionare il modello migliore
    final lowerInput = userInput.toLowerCase();
    
    // Per coding e sviluppo -> Claude 4 Sonnet
    if (lowerInput.contains('codice') || lowerInput.contains('code') ||
        lowerInput.contains('flutter') || lowerInput.contains('dart') ||
        lowerInput.contains('debug') || lowerInput.contains('errore') ||
        lowerInput.contains('refactor') || lowerInput.contains('ottimizza')) {
      return 'claude-4-sonnet';
    }
    
    // Per creatività e brainstorming -> GPT-4
    if (lowerInput.contains('crea') || lowerInput.contains('genera') ||
        lowerInput.contains('scrivi') || lowerInput.contains('inventa') ||
        lowerInput.contains('idea') || lowerInput.contains('design')) {
      return 'gpt-4-turbo';
    }
    
    // Per analisi e spiegazioni -> Claude 4 Sonnet
    if (lowerInput.contains('spiega') || lowerInput.contains('analizza') ||
        lowerInput.contains('cosa') || lowerInput.contains('perché') ||
        lowerInput.contains('come funziona')) {
      return 'claude-4-sonnet';
    }
    
    // Default -> Claude 4 Sonnet (migliore per sviluppo)
    return 'claude-4-sonnet';
  }

  void _showBeautifulModelSelector() {
    // Lista dei modelli curati
    final curatedModels = [
      {'id': 'auto', 'name': 'Auto', 'provider': 'SMART', 'description': 'Scelta automatica del modello migliore'},
      {'id': 'claude-4.1-sonnet', 'name': 'Claude 4.1 Sonnet', 'provider': 'ANTHROPIC', 'description': 'Migliore per coding e sviluppo'},
      {'id': 'claude-4.1-opus', 'name': 'Claude 4.1 Opus', 'provider': 'ANTHROPIC', 'description': 'Massima qualità per task complessi'},
      {'id': 'gpt-5', 'name': 'GPT-5', 'provider': 'OPENAI', 'description': 'Nuova generazione per creatività'},
      {'id': 'gemini-2.5-pro', 'name': 'Gemini 2.5 Pro', 'provider': 'GOOGLE', 'description': 'Potente e veloce per analisi'},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Container(
          height: 420, // Altezza fissa per 5 opzioni
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        child: Column(
          children: [
            // Header semplificato
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seleziona Modello',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lista modelli pulita
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: curatedModels.length,
                itemBuilder: (context, index) {
                  final model = curatedModels[index];
                  final isSelected = _selectedModel == model['id'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedModel = model['id']!;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.border(brightness).withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icona modello
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.textSecondary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  model['id'] == 'auto' 
                                    ? Icons.auto_fix_high_rounded
                                    : Icons.psychology_rounded,
                                  color: isSelected 
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(alpha: 0.7),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info modello
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            model['name']!,
                        style: TextStyle(
                          color: AppColors.titleText(brightness),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getProviderColor(model['provider']!).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            model['provider']!,
                                            style: TextStyle(
                                              color: _getProviderColor(model['provider']!),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model['description']!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Checkmark
                              if (isSelected)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        );
      },
    );
  }
  
  Widget _buildAnimatedSidebarButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Animazione al tap
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        Scaffold.of(context).openDrawer();
      },
      onTapDown: (_) {
        // Inizio animazione al press
        _animationController.forward();
      },
      onTapCancel: () {
        // Annulla animazione se il tap viene cancellato
        _animationController.reverse();
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background animato
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _textPurple.withValues(alpha: 0.15 * _animationController.value),
                        _textPurple.withValues(alpha: 0.05 * _animationController.value),
                      ],
                      stops: [0.3, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2 * _animationController.value),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
            // Linee animate custom
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final animValue = _animationController.value;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Prima linea
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: 18 - (4 * animValue),
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.textPrimary,
                            AppColors.primary.withValues(alpha: 0.3 + (0.7 * animValue)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Seconda linea (si accorcia di più)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: 14 - (6 * animValue),
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.textPrimary.withValues(alpha: 0.8),
                            AppColors.primary.withValues(alpha: 0.2 + (0.8 * animValue)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Terza linea
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: 12 - (2 * animValue),
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.textPrimary.withValues(alpha: 0.6),
                            AppColors.primary.withValues(alpha: 0.1 + (0.9 * animValue)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Effetto ripple al tap
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3 * _animationController.value),
                        blurRadius: 8 * _animationController.value,
                        offset: Offset.zero,
                        spreadRadius: 2 * _animationController.value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getProviderColor(String provider) {
    switch (provider) {
      case 'SMART':
        return AppColors.success;
      case 'ANTHROPIC':
        return AppColors.primary;
      case 'OPENAI':
        return const Color(0xFF00A67E);
      case 'GOOGLE':
        return const Color(0xFF4285F4);
      default:
        return AppColors.textSecondary;
    }
  }

  // Placeholder methods - implementa secondo necessità
  void _initializeSampleChats() {
    final now = DateTime.now();
    _chatFolders.addAll([
      ChatFolder(
        id: 'flutter',
        name: 'Flutter Projects',
        icon: '📱',
        color: AppColors.primary,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ChatFolder(
        id: 'debug',
        name: 'Debug & Fixes',
        icon: '🐛',
        color: AppColors.error,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
    
    _chatHistory.addAll([
      ChatSession(
        id: '1',
        title: 'Avvio Applicazione Flutter',
        createdAt: now.subtract(const Duration(hours: 2)),
        lastUsed: now.subtract(const Duration(minutes: 30)),
        messages: [],
        aiModel: 'claude-4-sonnet',
        folderId: 'flutter',
        repositoryId: 'warp-container',
        repositoryName: 'warp-container',
      ),
      ChatSession(
        id: '2',
        title: 'Installazione Dipendenze',
        createdAt: now.subtract(const Duration(hours: 4)),
        lastUsed: now.subtract(const Duration(hours: 1)),
        messages: [],
        aiModel: 'claude-4-sonnet',
        folderId: 'flutter',
        repositoryId: 'warp-mobile-ai-ide',
        repositoryName: 'warp-mobile-ai-ide',
      ),
      ChatSession(
        id: '3',
        title: 'Come ottimizzare performance Flutter?',
        createdAt: now.subtract(const Duration(days: 1)),
        lastUsed: now.subtract(const Duration(hours: 6)),
        messages: [],
        aiModel: 'claude-4-sonnet',
        folderId: 'flutter',
      ),
    ]);
    _updateFilteredChats();
  }

  void _updateFilteredChats() {
    if (_searchQuery.isEmpty) {
      _filteredChats = List.from(_chatHistory);
    } else {
      _filteredChats = _chatHistory.where((chat) {
        final titleMatch = chat.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final messageMatch = chat.messages.any((message) => 
          message.content.toLowerCase().contains(_searchQuery.toLowerCase()));
        return titleMatch || messageMatch;
      }).toList();
    }
  }

  void _loadGitHubCredentials() async {
    try {
      final isAuthenticated = await _gitHubService.isAuthenticated();
      if (isAuthenticated) {
        final user = await _gitHubService.getStoredUser();
        if (user != null) {
          setState(() {
            _isGitHubConnected = true;
            _gitHubUser = user;
            _gitHubUsername = user.login;
          });
          
          // Load repositories in background
          _loadGitHubRepositories();
        }
      }
    } catch (e) {
      print('Error loading GitHub credentials: $e');
    }
  }

  /// Initialize deep link handler for OAuth callbacks
  void _initializeDeepLinkHandler() {
    try {
      DeepLinkHandler.initialize();
      
      // Listen for GitHub OAuth callbacks
      DeepLinkHandler.linkStream.listen((Uri uri) async {
        print('🔗 Received deep link: $uri');
        
        if (uri.scheme == 'warp-mobile' && uri.host == 'oauth' && uri.pathSegments.contains('github')) {
          print('🔗 Processing GitHub OAuth callback: $uri');
          
          final success = await DeepLinkHandler.handleGitHubCallback(uri);
          
          if (success) {
            print('✅ OAuth callback successful, updating UI');
            _loadGitHubCredentials();
            _loadGitHubRepositories();
            _showSnackBar('✅ Connesso a GitHub con successo!');
          } else {
            print('❌ OAuth callback failed');
            _showSnackBar('❌ Errore durante la connessione a GitHub');
          }
          
          setState(() {
            _isConnectingToGitHub = false;
          });
        }
      }, onError: (error) {
        print('❌ Deep link stream error: $error');
        setState(() {
          _isConnectingToGitHub = false;
        });
      });
      
      // Start a polling mechanism to check if GitHub authentication succeeded
      _startOAuthPolling();
      
    } catch (e) {
      print('❌ Error initializing deep link handler: $e');
    }
  }
  
  /// Start polling to check if OAuth completed successfully
  void _startOAuthPolling() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isConnectingToGitHub) {
        timer.cancel();
        return;
      }
      
      // Check if we suddenly have a GitHub token (OAuth completed)
      _gitHubService.isAuthenticated().then((isAuthenticated) {
        if (isAuthenticated && _isConnectingToGitHub) {
          print('🔄 Polling detected OAuth success!');
          timer.cancel();
          _loadGitHubCredentials();
          _loadGitHubRepositories();
          _showSnackBar('✅ Connesso a GitHub con successo!');
          setState(() {
            _isConnectingToGitHub = false;
          });
        }
      }).catchError((error) {
        print('❌ OAuth polling error: $error');
      });
    });
  }
  
  /// Test OAuth callback manually (for debugging)
  void _testOAuthCallback() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        title: Text(
          'Test OAuth Callback',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Per testare il callback OAuth, copia l\'URL dal browser dopo l\'autorizzazione e incollalo qui:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'URL Callback',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'warp-mobile://oauth/github?code=...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.textSecondary),
                ),
                filled: true,
                fillColor: AppColors.background(brightness).withValues(alpha: 0.3),
              ),
              onSubmitted: (url) async {
                Navigator.of(context).pop();
                if (url.isNotEmpty) {
                  try {
                    final uri = Uri.parse(url);
                    setState(() {
                      _isConnectingToGitHub = true;
                    });
                    
                    final success = await DeepLinkHandler.handleGitHubCallback(uri);
                    
                    if (success) {
                      _loadGitHubCredentials();
                      _loadGitHubRepositories();
                      _showSnackBar('✅ Test OAuth completato con successo!');
                    } else {
                      _showSnackBar('❌ Test OAuth fallito');
                    }
                    
                    setState(() {
                      _isConnectingToGitHub = false;
                    });
                  } catch (e) {
                    _showSnackBar('❌ URL non valido: $e');
                    setState(() {
                      _isConnectingToGitHub = false;
                    });
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
  
  void _connectGitHub() async {
    // Try OAuth first, fallback to token dialog if it fails
    setState(() {
      _isConnectingToGitHub = true;
    });
    
    try {
      final success = await _gitHubService.startOAuthFlow();
      
      if (!success) {
        _showSnackBar('❌ Impossibile avviare OAuth, prova con il token');
        setState(() {
          _isConnectingToGitHub = false;
        });
        _showGitHubConnectionDialog();
        return;
      }
      
      // Set a timeout to reset loading state if callback doesn't arrive
      Timer(const Duration(seconds: 30), () {
        if (_isConnectingToGitHub) {
          print('⏰ OAuth timeout - showing fallback options');
          setState(() {
            _isConnectingToGitHub = false;
          });
          _showSnackBar('⏰ Timeout OAuth - puoi usare il token manuale');
          _showGitHubConnectionDialog();
        }
      });
      
    } catch (e) {
      print('❌ GitHub connection error: $e');
      _showSnackBar('❌ Errore OAuth: $e');
      setState(() {
        _isConnectingToGitHub = false;
      });
      _showGitHubConnectionDialog();
    }
  }
  
  void _showGitHubConnectionDialog() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        title: Row(
          children: [
            Icon(Icons.code, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Connetti a GitHub',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // OAuth Option (now available but may have deep link issues)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'OAuth (Disponibile)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configurato con GitHub OAuth App reale. Potrebbe richiedere test manual su simulatore iOS.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Personal Access Token Option  
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showTokenDialog();
              },
              icon: Icon(Icons.key, size: 16),
              label: const Text('Usa Personal Access Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTokenDialog() {
    final tokenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => _buildGitHubAuthDialog(),
    );
  }
  
  Future<void> _loadGitHubRepositories() async {
    try {
      setState(() {
        _isConnectingToGitHub = true;
      });
      
      final repositories = await _gitHubService.fetchUserRepositories(
        sort: 'updated',
        direction: 'desc',
        perPage: 100,
      );
      
      setState(() {
        _gitHubRepositories = repositories;
        _isConnectingToGitHub = false;
      });
      
      if (repositories.isNotEmpty) {
        _showSnackBar('✅ Caricate ${repositories.length} repository da GitHub!');
      }
    } catch (e) {
      setState(() {
        _isConnectingToGitHub = false;
      });
      _showSnackBar('❌ Errore nel caricamento repository: $e');
    }
  }
  
  Future<void> _authenticateWithToken(String token) async {
    try {
      setState(() {
        _isConnectingToGitHub = true;
      });
      
      final success = await _gitHubService.authenticateWithToken(token);
      if (success) {
        final user = await _gitHubService.getStoredUser();
        setState(() {
          _isGitHubConnected = true;
          _gitHubUser = user;
          _gitHubUsername = user?.login;
          _isConnectingToGitHub = false;
        });
        
        Navigator.of(context).pop(); // Close dialog
        _showSnackBar('✅ Connesso a GitHub come @${user?.login}!');
        
        // Load repositories
        await _loadGitHubRepositories();
      } else {
        setState(() {
          _isConnectingToGitHub = false;
        });
        _showSnackBar('❌ Token non valido. Verifica il tuo Personal Access Token.');
      }
    } catch (e) {
      setState(() {
        _isConnectingToGitHub = false;
      });
      _showSnackBar('❌ Errore di autenticazione: $e');
    }
  }
  
  Future<void> _disconnectGitHub() async {
    try {
      await _gitHubService.logout();
      setState(() {
        _isGitHubConnected = false;
        _gitHubUser = null;
        _gitHubUsername = null;
        _gitHubRepositories.clear();
        _selectedRepository = null;
      });
      _showSnackBar('GitHub disconnesso');
    } catch (e) {
      _showSnackBar('Errore disconnessione GitHub: $e');
    }
  }

  void _startNewChat() {
    setState(() {
      _terminalItems.clear();
      _hasInteracted = false;
      _attachedImages.clear();
      _taggedFiles.clear();
      _currentChatSession = null;
      _currentChatTitle = null;
    });
    _commandController.clear();
    Navigator.pop(context);
    
    // Focus sulla textfield dopo aver chiuso il drawer
    Future.delayed(const Duration(milliseconds: 300), () {
      _commandFocusNode.requestFocus();
    });
  }

  void _showGitHubSidebarPanel() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      barrierLabel: 'GitHub Sidebar',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0), // Slide da sinistra
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // Background overlay
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // GitHub Sidebar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildGitHubSidebarDrawer(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGitHubSidebarDrawer() {
    final brightness = Theme.of(context).brightness;
    return Drawer(
      backgroundColor: AppColors.surface(brightness),
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            // Top header vuoto (stesso spacing della sidebar principale)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const SizedBox.shrink(),
            ),
            
            // Search bar sostituita con status GitHub
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _buildGitHubStatusBar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Pulsanti GitHub (sostituiscono i pulsanti principali)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (!_isGitHubConnected)
                    _buildSidebarButton(
                      icon: Icons.account_tree_outlined,
                      text: 'Connetti GitHub',
                      onTap: _showTokenDialog,
                      isActive: false,
                    ),
                  if (_isGitHubConnected) ...[
                    _buildSidebarButton(
                      icon: Icons.refresh_rounded,
                      text: 'Ricarica Repository',
                      onTap: _loadGitHubRepositories,
                      isActive: false,
                    ),
                    const SizedBox(height: 8),
                    _buildSidebarButton(
                      icon: Icons.logout_rounded,
                      text: 'Disconnetti',
                      onTap: () {
                        _disconnectGitHub();
                        Navigator.pop(context);
                      },
                      isActive: false,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Repository list (sostituisce la chat history)
            Expanded(
              child: _isGitHubConnected
                  ? _buildGitHubRepositoryHistory()
                  : _buildGitHubEmptyState(),
            ),
            
            // Bottom section con close button (sostituisce user info)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border(brightness),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    // Icona GitHub con gradiente purple
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleMedium.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_tree_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // GitHub info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GitHub',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _isGitHubConnected 
                                ? 'Connesso • @${_gitHubUsername ?? "Unknown"}'
                                : 'Non connesso',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitHubStatusBar() {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        enabled: false, // Solo per display, non funzionale
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: _isGitHubConnected 
              ? 'Repository GitHub...'
              : 'GitHub non connesso...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _isGitHubConnected 
                  ? Icons.account_tree_rounded
                  : Icons.account_tree_outlined,
              color: _isGitHubConnected 
                  ? AppColors.purpleMedium
                  : AppColors.textSecondary,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubRepositoryHistory() {
    final brightness = Theme.of(context).brightness;
    if (_isConnectingToGitHub) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purpleMedium),
            ),
            const SizedBox(height: 16),
            Text(
              'Caricamento repository...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_gitHubRepositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna repository',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le tue repository appariranno qui',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Header Repository
        Row(
          children: [
            Text(
              'Repository',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_up,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Lista repository
        ..._gitHubRepositories.map((repo) => _buildGitHubRepositoryItem(repo)),
      ],
    );
  }

  Widget _buildGitHubEmptyState() {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: AppColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'GitHub Integration',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connetti il tuo account per accedere alle repository',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitHubRepositoryItem(github_service.GitHubRepository repo) {
    final brightness = Theme.of(context).brightness;
    final isSelected = _selectedRepository?.id == repo.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRepository = repo;
          });
          Navigator.pop(context);
          _showSnackBar('Repository ${repo.name} selezionata!');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.surface(brightness).withValues(alpha: 0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ) : null,
          ),
          child: Row(
            children: [
              // Icona cartella a sinistra
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 2),
                child: Icon(
                  repo.isPrivate ? Icons.folder_rounded : Icons.folder_outlined,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
              // Contenuto repository
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome repository e linguaggio
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            repo.name,
                            style: TextStyle(
                              color: isSelected 
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (repo.language != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getLanguageColor(repo.language!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            repo.language!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.purpleMedium,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    
                    // Descrizione e stelle
                    if (repo.description != null && repo.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              repo.description!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (repo.stargazersCount > 0) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star_outline, size: 10, color: AppColors.textTertiary),
                            const SizedBox(width: 2),
                            Text(
                              '${repo.stargazersCount}',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  IconData _getLanguageIcon(String language) {
    switch (language?.toLowerCase() ?? '') {
      case 'dart':
      case 'flutter':
        return Icons.flutter_dash;
      case 'javascript':
      case 'js':
      case 'typescript':
      case 'ts':
        return Icons.code_rounded;
      case 'python':
        return Icons.psychology_rounded;
      case 'java':
        return Icons.coffee_rounded;
      case 'swift':
        return Icons.phone_iphone_rounded;
      case 'kotlin':
        return Icons.android_rounded;
      case 'go':
        return Icons.speed_rounded;
      case 'rust':
        return Icons.settings_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  void _loadChatSession(ChatSession chat) {
    setState(() {
      _terminalItems = List.from(chat.messages);
      _selectedModel = chat.aiModel;
      _hasInteracted = true;
      _currentChatSession = chat;
      _currentChatTitle = chat.title;
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  void _saveChatSession() {
    if (_terminalItems.isEmpty) return;
    
    final sessionTitle = _generateSessionTitle();
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: sessionTitle,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
      messages: List.from(_terminalItems),
      aiModel: _selectedModel,
      folderId: null,
      repositoryId: _selectedRepository?.id.toString(),
      repositoryName: _selectedRepository?.name,
    );
    
    setState(() {
      _chatHistory.insert(0, session);
      if (_chatHistory.length > 20) {
        _chatHistory.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        _chatHistory.removeAt(0);
      }
    });
  }

  String _generateSessionTitle() {
    if (_terminalItems.isEmpty) return 'Chat Vuota';
    
    final firstCommand = _terminalItems.firstWhere(
      (item) => item.type == TerminalItemType.command,
      orElse: () => _terminalItems.first,
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
  
  String _generateMeaningfulTitle(String command) {
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
          ? 'Build Flutter per $platform' 
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
        return '${command.substring(0, 40)}...';
      }
      return command; // Restituisci la domanda completa
    }
    
    // Fallback per altri comandi
    if (command.length > 40) {
      return '${command.substring(0, 40)}...';
    }
    return command;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}g fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m fa';
    } else {
      return 'Ora';
    }
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _attachedImages.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Errore nel caricamento immagini: $e');
    }
  }

  void _removeImage(File image) {
    setState(() {
      _attachedImages.remove(image);
    });
  }

  Future<void> _selectFilesToTag() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _taggedFiles.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Errore nel tagging file: $e');
    }
  }

  void _removeTaggedFile(File file) {
    setState(() {
      _taggedFiles.remove(file);
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      bool hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) {
        _showSnackBar('Impossibile accedere al microfono');
        return;
      }
      
      await _audioRecorder.start(
        path: '/tmp/recording.m4a',
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showSnackBar('Errore avvio registrazione: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _currentRecordingPath = path;
      });
      
      if (path != null) {
        _showSnackBar('Registrazione salvata!');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showSnackBar('Errore stop registrazione: $e');
    }
  }

  void _showSnackBar(String message) {
    // Notifiche disabilitate per un'interfaccia più pulita
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(message),
    //       backgroundColor: AppColors.surface(brightness),
    //       behavior: SnackBarBehavior.floating,
    //     ),
    //   );
    // }
  }
  
  Widget _buildGitHubAuthDialog() {
    final brightness = Theme.of(context).brightness;
    final tokenController = TextEditingController();
    
    return AlertDialog(
      backgroundColor: AppColors.surface(brightness),
      title: Row(
        children: [
          Icon(Icons.code, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Connetti a GitHub',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per connettere Warp alle tue repository GitHub, hai bisogno di un Personal Access Token.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background(brightness).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                           size: 16, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text(
                        'Come creare il token:',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Vai su github.com/settings/tokens\n'
                    '2. Clicca "Generate new token (classic)"\n'
                    '3. Seleziona scopes: repo, user:email\n'
                    '4. Copia e incolla il token qui sotto',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              obscureText: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.textSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.background(brightness).withValues(alpha: 0.3),
                prefixIcon: Icon(Icons.key, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            if (_isConnectingToGitHub)
              LinearProgressIndicator(
                backgroundColor: AppColors.surface(brightness),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnectingToGitHub ? null : () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Annulla',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isConnectingToGitHub ? null : () {
            final token = tokenController.text.trim();
            if (token.isNotEmpty) {
              _authenticateWithToken(token);
            } else {
              _showSnackBar('⚠️ Inserisci un token valido');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
          child: _isConnectingToGitHub
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                  ),
                )
              : const Text('Connetti'),
        ),
      ],
    );
  }

  Future<void> _initializeTerminal() async {
    await TerminalService().initialize();
  }
  
  void _setupTerminalOutputListener() {
    // Listen to terminal output stream for real-time updates
    terminalOutputStreamController.stream.listen((result) {
      if (mounted) {
        setState(() {
          // Add output to terminal items if not already added
          if (result.output.isNotEmpty && 
              (_terminalItems.isEmpty || _terminalItems.last.content != result.output)) {
            _terminalItems.add(
              TerminalItem(
                content: result.output,
                type: result.isSuccess ? TerminalItemType.output : TerminalItemType.error,
                timestamp: DateTime.now(),
              )
            );
          }
          
          // Update preview URL from Docker backend
          _updatePreviewFromTerminalService();
          
          // Fallback pattern matching for local mode
          if (_previewUrl == null) {
            _checkForRunningApp(result.output);
          }
        });
        
        // Auto-scroll to bottom
        _scrollToBottom();
      }
    });
  }

  void _onInputChanged(String value) {
    print('Input changed: "$value" - Terminal mode: $_isTerminalMode'); // Debug
    
    if (!_isTerminalMode) {
      setState(() {
        _showAutocomplete = false;
        _autocompleteOptions = [];
      });
      return;
    }

    if (value.trim().isEmpty) {
      setState(() {
        _showAutocomplete = false;
        _autocompleteOptions = [];
        _selectedAutocompleteIndex = -1;
      });
      return;
    }

    // Get autocomplete suggestions
    try {
      List<AutocompleteOption> suggestions = AutocompleteService()
          .getSuggestions(value, TerminalService().currentDirectory);
      
      print('Found ${suggestions.length} autocomplete suggestions'); // Debug
      for (var suggestion in suggestions.take(3)) {
        print('  - ${suggestion.icon} ${suggestion.text} (${suggestion.type})');
      }

      setState(() {
        _autocompleteOptions = suggestions;
        _showAutocomplete = suggestions.isNotEmpty && _commandFocusNode.hasFocus;
        _selectedAutocompleteIndex = -1;
      });
    } catch (e) {
      print('Autocomplete error: $e'); // Debug
      setState(() {
        _showAutocomplete = false;
        _autocompleteOptions = [];
      });
    }
  }

  Widget _buildAutocompleteOverlay() {
    final brightness = Theme.of(context).brightness;
    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.of(context).padding.bottom + 150, // Above input area
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 220,
            minHeight: 60,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, -8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _autocompleteOptions.length,
              itemBuilder: (context, index) {
                final option = _autocompleteOptions[index];
                final isSelected = index == _selectedAutocompleteIndex;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectAutocompleteOption(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Text(
                            option.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.text,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'SF Mono',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (option.description.isNotEmpty)
                                  Text(
                                    option.description,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(option.type).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeLabel(option.type),
                              style: TextStyle(
                                color: _getTypeColor(option.type),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _selectAutocompleteOption(AutocompleteOption option) {
    // Replace the current input with the selected option
    String currentText = _commandController.text;
    List<String> parts = currentText.split(' ');
    
    if (parts.isNotEmpty) {
      // Replace the last part with the selected option
      if (option.type == AutocompleteType.file || option.type == AutocompleteType.directory) {
        // For file/directory suggestions, we might need to handle paths differently
        String lastPart = parts.last;
        if (lastPart.contains('/')) {
          int lastSlashIndex = lastPart.lastIndexOf('/');
          String pathPrefix = lastPart.substring(0, lastSlashIndex + 1);
          String newText = parts.sublist(0, parts.length - 1).join(' ');
          if (newText.isNotEmpty) newText += ' ';
          newText += pathPrefix + option.text;
          _commandController.text = newText;
        } else {
          parts[parts.length - 1] = option.text;
          _commandController.text = parts.join(' ');
        }
      } else {
        // For commands, replace the entire input if it's a single word, or just the last part
        if (parts.length == 1) {
          _commandController.text = option.text;
        } else {
          parts[parts.length - 1] = option.text;
          _commandController.text = parts.join(' ');
        }
      }
    }
    
    // Position cursor at end
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commandController.text.length),
    );
    
    setState(() {
      _showAutocomplete = false;
      _autocompleteOptions = [];
    });
  }

  Color _getTypeColor(AutocompleteType type) {
    switch (type) {
      case AutocompleteType.command:
        return AppColors.primary;
      case AutocompleteType.directory:
        return AppColors.success;
      case AutocompleteType.file:
        return const Color(0xFF38B2AC);
      case AutocompleteType.flag:
        return const Color(0xFF9F7AEA);
    }
  }

  String _getTypeLabel(AutocompleteType type) {
    switch (type) {
      case AutocompleteType.command:
        return 'CMD';
      case AutocompleteType.directory:
        return 'DIR';
      case AutocompleteType.file:
        return 'FILE';
      case AutocompleteType.flag:
        return 'FLAG';
    }
  }
  
  // Preview functionality
  void _updatePreviewFromTerminalService() {
    final terminalService = TerminalService();
    
    print('🔍 Debug: Checking for web server...');
    print('🔍 Debug: hasWebServerRunning: ${terminalService.hasWebServerRunning}');
    print('🔍 Debug: exposedPorts: ${terminalService.exposedPorts}');
    
    if (terminalService.hasWebServerRunning) {
      // Usa l'URL dinamico restituito dal server AWS invece di URL fisso
      final webUrls = terminalService.exposedPorts.values.toList();
      String? webUrl;
      
      // Usa l'URL dinamico dal backend AWS ECS invece di localhost hardcoded
      if (webUrls.isNotEmpty) {
        // Filtra gli URL localhost per usare solo URL pubblici
        webUrl = webUrls.firstWhere(
          (url) => !url.contains('localhost') && !url.contains('127.0.0.1'),
          orElse: () => webUrls.first, // Fallback al primo se non ci sono URL pubblici
        );
      } else {
        // Solo come fallback se non ci sono URL dal backend
        print('⚠️ Warning: Nessun URL dal backend, usando localhost come fallback');
        webUrl = 'http://localhost:3001';
      }
      
      print('🔍 Debug: Using dynamic web URL: $webUrl');
      if (webUrl != _previewUrl) {
        setState(() {
          _previewUrl = webUrl;
        });
        print('🚀 Web server detected from backend: $webUrl');
        print('🔍 Debug: Preview URL set to: $_previewUrl');
        
        // Show a notification that the preview is available
        _showSnackBar('🎆 Server avviato! Preview disponibile');
      }
    } else {
      print('🔍 Debug: No web server running detected');
    }
  }
  
  void _checkForRunningApp(String output) {
    // Check for various server/app running patterns
    final patterns = [
      // Flutter - Enhanced patterns
      RegExp(r'A web server for Flutter web application is available at:\s*(https?://[^\s]+)', caseSensitive: false),
      RegExp(r'Flutter\s+web\s+server.*?started.*?(https?://[^\s]+)', caseSensitive: false),
      RegExp(r'Application\s+started.*?(https?://[^\s]+)', caseSensitive: false),
      RegExp(r'Dev\s+server\s+running.*?(https?://[^\s]+)', caseSensitive: false),
      RegExp(r'Flutter web server.*http://[^\s]+', caseSensitive: false),
      RegExp(r'Serving at.*http://[^\s]+', caseSensitive: false),
      RegExp(r'Web development server running.*?(https?://[^\s]+)', caseSensitive: false),
      
      // React
      RegExp(r'Local:\s+http://[^\s]+', caseSensitive: false),
      RegExp(r'On Your Network:\s+http://[^\s]+', caseSensitive: false),
      
      // Node.js/Express
      RegExp(r'Server.*running.*http://[^\s]+', caseSensitive: false),
      RegExp(r'App.*listening.*http://[^\s]+', caseSensitive: false),
      
      // Python
      RegExp(r'Running on\s+http://[^\s]+', caseSensitive: false),
      
      // Generic localhost patterns
      RegExp(r'(https?://localhost:\d+)', caseSensitive: false),
      RegExp(r'(https?://127\.0\.0\.1:\d+)', caseSensitive: false),
      RegExp(r'(https?://0\.0\.0\.0:\d+)', caseSensitive: false),
      RegExp(r'https?://[^\s]+:[0-9]+', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(output);
      if (match != null) {
        String url = match.group(0)!;
        // Extract clean URL
        final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(url);
        if (urlMatch != null) {
          setState(() {
            _previewUrl = urlMatch.group(0);
          });
          print('🚀 App detected running at: $_previewUrl'); // Debug
          break;
        }
      }
    }
  }
  
  void _openPreview() {
    if (_previewUrl == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewWebScreen(url: _previewUrl!),
      ),
    );
  }
  
  Future<void> _stopFlutterProcess() async {
    if (_selectedRepository == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Set repository context before stopping
      TerminalService().setCurrentRepository(_selectedRepository?.name);
      
      // Execute stop command - this will be handled by our backend
      final result = await TerminalService().executeCommand('flutter stop');
      
      setState(() {
        _terminalItems.add(
          TerminalItem(
            content: result.output.isNotEmpty ? result.output : '🛑 Flutter process stopped',
            type: result.isSuccess ? TerminalItemType.system : TerminalItemType.error,
            timestamp: DateTime.now(),
          )
        );
        
        // Clear preview URL when stopped
        if (result.isSuccess) {
          _previewUrl = null;
        }
        
        _isLoading = false;
      });
      
      if (result.isSuccess) {
        _showSnackBar('🛑 Processo Flutter terminato');
      } else {
        _showSnackBar('❌ Errore nel fermare il processo');
      }
      
    } catch (e) {
      setState(() {
        _terminalItems.add(
          TerminalItem(
            content: 'Errore nel fermare il processo Flutter: $e',
            type: TerminalItemType.error,
            timestamp: DateTime.now(),
          )
        );
        _isLoading = false;
      });
      _showSnackBar('❌ Errore nel fermare il processo');
    }
    
    _scrollToBottom();
  }
  
  // GitHub Animated Button Widget
  Widget _buildAnimatedGitHubButton() {
    final brightness = Theme.of(context).brightness;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _gitHubScaleAnimation,
        _gitHubGlowAnimation,
        _gitHubSparkleAnimation,
        _gitHubColorAnimation
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _gitHubScaleAnimation.value,
          child: GestureDetector(
            onTapDown: (details) => _handleGitHubTapDown(),
            onTapUp: (details) => _handleGitHubTapUp(),
            onTapCancel: () => _handleGitHubTapCancel(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                // Dynamic gradient based on animation
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      AppColors.surface(brightness).withValues(alpha: 0.3),
                      const Color(0xFF6366f1),
                      _gitHubGlowAnimation.value,
                    )!,
                    Color.lerp(
                      Colors.transparent,
                      const Color(0xFF8b5cf6),
                      _gitHubGlowAnimation.value,
                    )!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    AppColors.textSecondary.withValues(alpha: 0.2),
                    const Color(0xFF6366f1),
                    _gitHubGlowAnimation.value,
                  )!,
                  width: 1 + (_gitHubGlowAnimation.value * 0.5),
                ),
                // Glow effect
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366f1).withValues(alpha: _gitHubGlowAnimation.value * 0.4),
                    blurRadius: 8 + (_gitHubGlowAnimation.value * 12),
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF8b5cf6).withValues(alpha: _gitHubGlowAnimation.value * 0.2),
                    blurRadius: 16 + (_gitHubGlowAnimation.value * 8),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main button content
                  Row(
                    children: [
                      // Animated icon with rotation
                      Transform.rotate(
                        angle: _gitHubSparkleAnimation.value * 0.1,
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: _gitHubColorAnimation.value ?? AppColors.textSecondary,
                          size: 18 + (_gitHubGlowAnimation.value * 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Animated text
                      Text(
                        'GitHub',
                        style: TextStyle(
                          color: _gitHubColorAnimation.value ?? AppColors.textSecondary,
                          fontSize: 14 + (_gitHubGlowAnimation.value * 0.5),
                          fontWeight: FontWeight.lerp(
                            FontWeight.w400,
                            FontWeight.w600,
                            _gitHubGlowAnimation.value,
                          ),
                          letterSpacing: _gitHubGlowAnimation.value * 0.5,
                        ),
                      ),
                    ],
                  ),
                  // Sparkle effects
                  if (_gitHubSparkleAnimation.value > 0) ..._buildSparkleEffects(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Sparkle effects
  List<Widget> _buildSparkleEffects() {
    final sparkles = <Widget>[];
    final sparklePositions = [
      const Offset(0.2, 0.3),
      const Offset(0.8, 0.2), 
      const Offset(0.1, 0.7),
      const Offset(0.9, 0.8),
      const Offset(0.5, 0.1),
    ];
    
    for (int i = 0; i < sparklePositions.length; i++) {
      final delay = i * 0.1;
      final adjustedAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _gitHubSparkleController,
        curve: Interval(delay, 1.0, curve: Curves.elasticOut),
      ));
      
      sparkles.add(
        Positioned(
          left: sparklePositions[i].dx * 250, // Approximate button width
          top: sparklePositions[i].dy * 40,   // Approximate button height
          child: Transform.scale(
            scale: adjustedAnimation.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: adjustedAnimation.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366f1).withValues(alpha: adjustedAnimation.value * 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return sparkles;
  }
  
  // GitHub button animation handlers
  void _handleGitHubTapDown() {
    setState(() {
      _isGitHubPressed = true;
    });
    
    // Multiple haptic feedbacks for richer feel
    HapticFeedback.selectionClick();
    
    // Start scale animation
    _gitHubScaleController.forward();
    
    // Start glow animation
    _gitHubGlowController.forward();
  }
  
  void _handleGitHubTapUp() {
    // Enhanced haptic sequence
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.selectionClick();
    });
    
    // Reverse scale animation
    _gitHubScaleController.reverse();
    
    // Start sparkle animation
    _gitHubSparkleController.forward().then((_) {
      _gitHubSparkleController.reset();
    });
    
    // Keep glow for a moment then fade
    Future.delayed(const Duration(milliseconds: 300), () {
      _gitHubGlowController.reverse();
    });
    
    setState(() {
      _isGitHubPressed = false;
      _showGitHubSidebar = true;
    });
    
    // Execute original action
    Navigator.pop(context); // Chiudi sidebar principale
    _showGitHubSidebarPanel();
  }
  
  void _handleGitHubTapCancel() {
    setState(() {
      _isGitHubPressed = false;
    });
    _gitHubScaleController.reverse();
    _gitHubGlowController.reverse();
  }
}

// Preview Screen
class PreviewScreen extends StatefulWidget {
  final String url;
  
  const PreviewScreen({super.key, required this.url});
  
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _currentUrl;
  
  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _initializeWebView();
  }
  
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore nel caricamento: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }
  
  void _refreshWebView() {
    _webViewController.reload();
  }
  
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Flutter Web'),
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _refreshWebView,
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Ricarica',
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // URL bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface(brightness).withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(Icons.link, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl ?? widget.url,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'SF Mono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border(brightness).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: WebViewWidget(
                controller: _webViewController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
