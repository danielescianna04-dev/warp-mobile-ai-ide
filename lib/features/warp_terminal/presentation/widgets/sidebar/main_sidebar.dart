import 'package:flutter/material.dart';
import '../../../../../shared/constants/app_colors.dart';
import '../../data/models/chat_session.dart';
import '../chat/chat_history_list.dart';

class MainSidebar extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final ChatSession? currentChat;
  final String? gitHubUsername;
  final bool isGitHubConnected;
  final FocusNode searchFocusNode;
  final VoidCallback onStartNewChat;
  final VoidCallback onOpenGitHub;
  final VoidCallback onOpenCreaApp;
  final VoidCallback onOpenSettings;
  final void Function(ChatSession chat) onLoadChatSession;

  const MainSidebar({
    super.key,
    required this.chatHistory,
    required this.currentChat,
    required this.gitHubUsername,
    required this.isGitHubConnected,
    required this.searchFocusNode,
    required this.onStartNewChat,
    required this.onOpenGitHub,
    required this.onOpenCreaApp,
    required this.onOpenSettings,
    required this.onLoadChatSession,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Drawer(
      backgroundColor: AppColors.surface(brightness),
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            // Top header vuoto (stesso spacing della sidebar GitHub)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const SizedBox.shrink(),
            ),
            
            // Search bar custom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _buildCustomSearchBar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Pulsanti principali
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSidebarButton(
                    icon: Icons.account_tree_outlined,
                    text: 'GitHub',
                    onTap: onOpenGitHub,
                    isActive: false,
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarButton(
                    icon: Icons.rocket_launch_outlined,
                    text: 'Crea App',
                    onTap: onOpenCreaApp,
                    isActive: false,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Chat history
            Expanded(
              child: _buildChatHistory(),
            ),
            
            // Bottom section con user info
            _buildUserSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSearchBar() {
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
        focusNode: searchFocusNode,
        style: TextStyle(
          color: AppColors.titleText(brightness),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(
            color: AppColors.bodyText(brightness).withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.bodyText(brightness),
              size: 18,
            ),
          ),
          suffixIcon: GestureDetector(
            onTap: onStartNewChat,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient(brightness),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
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

  Widget _buildChatHistory() {
    final brightness = Theme.of(context).brightness;
    if (chatHistory.isEmpty) {
      return Center(
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
                'Nessuna Chat',
                style: TextStyle(
                  color: AppColors.bodyText(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inizia una conversazione',
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Header sezioni
        _buildDateHeader('Today', true),
        const SizedBox(height: 8),
        ..._getChatsByDate('today').map(_buildChatItem),
        
        if (_getChatsByDate('yesterday').isNotEmpty) ...[ 
          const SizedBox(height: 16),
          _buildDateHeader('Yesterday', false),
          const SizedBox(height: 8),
          ..._getChatsByDate('yesterday').map(_buildChatItem),
        ],
        
        if (_getChatsByDate('week').isNotEmpty) ...[ 
          const SizedBox(height: 16),
          _buildDateHeader('Last 7 days', false),
          const SizedBox(height: 8),
          ..._getChatsByDate('week').map(_buildChatItem),
        ],
      ],
    );
  }

  Widget _buildDateHeader(String title, bool isExpanded) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.bodyText(brightness),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppColors.bodyText(brightness),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildChatItem(ChatSession chat) {
    final brightness = Theme.of(context).brightness;
    final isSelected = currentChat?.id == chat.id;
    final isGitHubChat = chat.repositoryId != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => onLoadChatSession(chat),
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
              color: AppColors.bodyText(brightness).withValues(alpha: 0.2),
              width: 1,
            ) : null,
          ),
          child: Row(
            children: [
              // Icona GitHub a sinistra
              Container(
                width: 20,
                child: isGitHubChat 
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              
              // Contenuto chat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title.length > 40 ? '${chat.title.substring(0, 40)}...' : chat.title,
                      style: TextStyle(
                        color: isSelected 
                            ? AppColors.titleText(brightness)
                            : AppColors.bodyText(brightness),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
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
    );
  }

  Widget _buildUserSection() {
    final brightness = Theme.of(context).brightness;
    return Container(
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
        onTap: onOpenSettings,
        child: Row(
          children: [
            // Avatar con gradiente purple
            Container(
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
                    'Warp AI Developer',
                    style: TextStyle(
                      color: AppColors.bodyText(brightness),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Badge PRO professionale
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bodyText(brightness).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.bodyText(brightness).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  color: AppColors.bodyText(brightness),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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
    
    return chatHistory.where((chat) {
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
}