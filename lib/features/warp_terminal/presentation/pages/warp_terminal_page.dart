import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/ai/ai_models.dart';
import '../../../../core/ai/ai_manager.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/terminal/terminal_service.dart';
import '../../../../core/terminal/autocomplete_service.dart';
import '../../../../core/terminal/syntax_highlighter.dart';
import '../../../../core/terminal/syntax_text_field.dart';
import '../../../../core/github/github_service.dart' as github_service;
import '../../../../core/github/deep_link_handler.dart';

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
  
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUsed,
    required this.messages,
    required this.aiModel,
    this.folderId,
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

class WarpTerminalPage extends StatefulWidget {
  const WarpTerminalPage({super.key});

  @override
  State<WarpTerminalPage> createState() => _WarpTerminalPageState();
}

class _WarpTerminalPageState extends State<WarpTerminalPage> with SingleTickerProviderStateMixin {
  late SyntaxHighlightingController _commandController;
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _outputScrollController = ScrollController();
  
  bool _hasInteracted = false;
  bool _isLoading = false;
  List<TerminalItem> _terminalItems = [];
  
  late AnimationController _animationController;
  
  // Nuove funzionalità
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  bool _isTerminalMode = true;
  bool _autoApprove = false;
  String _selectedModel = 'claude-4-sonnet';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildSidebar(),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: _hasInteracted 
                ? _buildTerminalOutput() 
                : _buildWelcomeView(context),
          ),
          // Input area always at bottom
          _buildInputArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    String title = 'Warp AI';
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
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.drag_handle, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        // Preview button (smart activation)
        IconButton(
          onPressed: _previewUrl != null ? _openPreview : null,
          icon: Icon(
            Icons.visibility,
            color: _previewUrl != null ? AppColors.success : AppColors.textTertiary,
          ),
          tooltip: _previewUrl != null ? 'Vedi Preview' : 'Nessuna app in esecuzione',
        ),
        // Stop process button (appears when preview is active)
        if (_previewUrl != null && _selectedRepository != null)
          IconButton(
            onPressed: _stopFlutterProcess,
            icon: Icon(
              Icons.stop_circle,
              color: AppColors.error,
            ),
            tooltip: 'Ferma Flutter Run',
          ),
        if (_terminalItems.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _terminalItems.clear();
                _hasInteracted = false;
                _previewUrl = null; // Reset preview quando clear
              });
            },
            icon: Icon(Icons.clear_all, color: AppColors.textSecondary),
            tooltip: 'Pulisci terminale',
          ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.aiGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.terminal,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warp AI IDE',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Mobile Development',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cerca nelle chat...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: AppColors.background,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chat sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Chat recenti
                  _buildChatSection(),
                  const SizedBox(height: 16),
                  // Repository GitHub
                  _buildGitHubSection(),
                ],
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // New chat button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startNewChat,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nuova Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildChatSection() {
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
          // User info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _gitHubUser?.avatarUrl != null 
                      ? NetworkImage(_gitHubUser!.avatarUrl) 
                      : null,
                  child: _gitHubUser?.avatarUrl == null 
                      ? Text(
                          _gitHubUsername?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gitHubUser?.name ?? '@$_gitHubUsername',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_gitHubUser?.name != null)
                        Text(
                          '@$_gitHubUsername',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.success, size: 16),
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
                color: AppColors.surface.withValues(alpha: 0.3),
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
                  backgroundColor: AppColors.surface.withValues(alpha: 0.5),
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
    final isSelected = _selectedRepository?.id == repo.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      repo.isPrivate ? Icons.lock : Icons.public,
                      size: 12,
                      color: repo.isPrivate ? AppColors.primary : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        repo.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                if (repo.description != null && repo.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    repo.description!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (repo.language != null) ...[
                      Container(
                        width: 8,
                        height: 8,
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
                          fontSize: 9,
                        ),
                      ),
                    ],
                    const Spacer(),
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
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF0175C2);
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'python':
        return const Color(0xFF3776AB);
      case 'java':
        return const Color(0xFFED8B00);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'rust':
        return const Color(0xFF000000);
      case 'swift':
        return const Color(0xFFFA7343);
      case 'kotlin':
        return const Color(0xFF7F52FF);
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildWelcomeView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.terminal,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Warp AI Terminal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Il futuro dello sviluppo mobile',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI: ${_getSelectedModelDisplayName().split(' ').first}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Pronto per assistenza',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scrivi un messaggio per iniziare',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Column(
      children: [
        // Attached files/images preview
        if (_attachedImages.isNotEmpty || _taggedFiles.isNotEmpty)
          _buildAttachmentsPreview(),
        // Terminal output
        Expanded(
          child: _terminalItems.isEmpty && !_isLoading 
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nuova Conversazione',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inizia scrivendo un messaggio qui sotto',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                controller: _outputScrollController,
                itemCount: _terminalItems.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _terminalItems.length && _isLoading) {
                    return Container(
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
                            'AI sta elaborando...',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
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
    Color defaultTextColor;
    String prefix;
    
    switch (item.type) {
      case TerminalItemType.command:
        defaultTextColor = AppColors.primary;
        prefix = _isTerminalMode ? '' : '❯ '; // Terminal mode shows full prompt in content
        break;
      case TerminalItemType.output:
        defaultTextColor = AppColors.textPrimary;
        prefix = '';
        break;
      case TerminalItemType.error:
        defaultTextColor = AppColors.error;
        prefix = '';
        break;
      case TerminalItemType.system:
        defaultTextColor = AppColors.success;
        prefix = '• ';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix.isNotEmpty)
            Text(
              prefix,
              style: TextStyle(
                color: defaultTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          Expanded(
            child: item.type == TerminalItemType.command && _isTerminalMode
              ? SelectableText.rich(
                  TextSpan(
                    children: TerminalSyntaxHighlighter.highlightCommand(
                      item.content, 
                      defaultTextColor,
                    ),
                  ),
                )
              : item.type == TerminalItemType.output
                ? SelectableText.rich(
                    TextSpan(
                      children: TerminalSyntaxHighlighter.highlightOutput(
                        item.content, 
                        defaultTextColor,
                      ),
                    ),
                  )
                : SelectableText(
                    item.content,
                    style: TextStyle(
                      color: defaultTextColor,
                      fontSize: 14,
                      fontFamily: 'SF Mono',
                      height: 1.3,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.1),
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
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Advanced controls - Top section
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Mode toggle
                      _buildModeToggle(),
                      const SizedBox(width: 12),
                      // Tools
                      _buildInputTools(),
                      const SizedBox(width: 12),
                      // Model selector
                      _buildModelSelector(),
                      const SizedBox(width: 16), // Extra padding at end
                    ],
                  ),
                ),
                // Main input row - Bottom section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                          hintText: _isTerminalMode 
                              ? 'Scrivi un comando...'
                              : 'Chiedi qualcosa all\'AI...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, 
                              vertical: 14,
                            ),
                            isDense: false,
                          ),
                          onChanged: _onInputChanged,
                          onSubmitted: _executeCommand,
                        ),
                    ),
                    // Send button - Integrated
                    Container(
                      margin: const EdgeInsets.all(6),
                      child: GestureDetector(
                        onTap: () {
                          if (_commandController.text.trim().isNotEmpty) {
                            _executeCommand(_commandController.text);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: _commandController.text.trim().isNotEmpty
                              ? AppColors.aiGradient
                              : LinearGradient(
                                  colors: [
                                    AppColors.textTertiary.withValues(alpha: 0.3),
                                    AppColors.textTertiary.withValues(alpha: 0.2),
                                  ],
                                ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _commandController.text.trim().isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: _commandController.text.trim().isNotEmpty
                              ? Colors.white
                              : AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.3),
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
                  ? AppColors.aiGradient
                  : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isTerminalMode
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
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
                  ? AppColors.aiGradient
                  : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: !_isTerminalMode
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
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
    return Row(
      children: [
        // Images
        _buildToolButton(
          icon: Icons.image,
          isActive: _attachedImages.isNotEmpty,
          onTap: _pickImages,
          badge: _attachedImages.length > 0 ? _attachedImages.length : null,
        ),
        const SizedBox(width: 8),
        // Files
        _buildToolButton(
          icon: Icons.attach_file,
          isActive: _taggedFiles.isNotEmpty,
          onTap: _selectFilesToTag,
          badge: _taggedFiles.length > 0 ? _taggedFiles.length : null,
        ),
        const SizedBox(width: 8),
        // Audio recording
        _buildToolButton(
          icon: _isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined,
          isActive: _isRecording || _currentRecordingPath != null,
          onTap: _toggleRecording,
          isRecording: _isRecording,
        ),
        const SizedBox(width: 8),
        // Auto approve
        _buildToolButton(
          icon: Icons.auto_mode,
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
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    int? badge,
    bool isRecording = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: isActive
                ? AppColors.aiGradient
                : LinearGradient(
                    colors: [
                      AppColors.background.withValues(alpha: 0.4),
                      AppColors.background.withValues(alpha: 0.2),
                    ],
                  ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  size: 16,
                ),
                if (isRecording)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.7),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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
    _commandController.dispose();
    _commandFocusNode.dispose();
    _outputScrollController.dispose();
    _animationController.dispose();
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
        // Execute AI command
        await AIManager.instance.switchModel(_selectedModel);
        
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
    final model = AIModel.allModels.firstWhere(
      (m) => m.id == _selectedModel,
      orElse: () => AIModel.allModels.first,
    );
    return model.displayName;
  }

  void _showBeautifulModelSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surface.withValues(alpha: 0.98),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seleziona Modello AI',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: AIModel.allModels.length,
                itemBuilder: (context, index) {
                  final model = AIModel.allModels[index];
                  final isSelected = model.id == _selectedModel;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedModel = model.id;
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
                                  color: AppColors.border.withValues(alpha: 0.1),
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
                                  Icons.auto_awesome_rounded,
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
                                            model.displayName,
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
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            model.provider.toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primary,
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
                                      'Modello ${model.provider} per sviluppo',
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
                },
              ),
            ),
          ],
        ),
      ),
    );
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
        title: 'Setup progetto Flutter',
        createdAt: now.subtract(const Duration(hours: 2)),
        lastUsed: now.subtract(const Duration(minutes: 30)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
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
                fillColor: AppColors.background.withOpacity(0.3),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
    
    return firstCommand.content.length > 50 
        ? '${firstCommand.content.substring(0, 50)}...'
        : firstCommand.content;
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Widget _buildGitHubAuthDialog() {
    final tokenController = TextEditingController();
    
    return AlertDialog(
      backgroundColor: AppColors.surface,
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
                color: AppColors.background.withOpacity(0.5),
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
                fillColor: AppColors.background.withOpacity(0.3),
                prefixIcon: Icon(Icons.key, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            if (_isConnectingToGitHub)
              LinearProgressIndicator(
                backgroundColor: AppColors.surface,
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
            color: AppColors.surface.withValues(alpha: 0.95),
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
      
      // Usa sempre il server locale per ora (demo funzionante)
      webUrl = 'http://localhost:3001';
      
      /* TODO: Sistemare backend AWS per servire Flutter Web correttamente
      if (webUrls.isNotEmpty) {
        webUrl = webUrls.first; // Usa il primo URL disponibile
      } else {
        // Fallback al server locale per test
        webUrl = 'http://localhost:3001';
      }
      */
      
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
        builder: (context) => PreviewScreen(url: _previewUrl!),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Flutter Web'),
        backgroundColor: AppColors.background,
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
            color: AppColors.surface.withValues(alpha: 0.5),
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
                  color: AppColors.border.withValues(alpha: 0.1),
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
