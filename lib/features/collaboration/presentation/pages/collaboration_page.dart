import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

class CollaborationPage extends StatefulWidget {
  const CollaborationPage({super.key});

  @override
  State<CollaborationPage> createState() => _CollaborationPageState();
}

class _CollaborationPageState extends State<CollaborationPage> with TickerProviderStateMixin {
  late TabController _collaborationTabController;
  bool _isConnectedToGitHub = false;

  @override
  void initState() {
    super.initState();
    _collaborationTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _collaborationTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Collaboration',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
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
            onPressed: () {
              setState(() {
                _isConnectedToGitHub = !_isConnectedToGitHub;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isConnectedToGitHub 
                      ? '✅ Connected to GitHub' 
                      : '❌ Disconnected from GitHub',
                  ),
                  backgroundColor: _isConnectedToGitHub 
                    ? AppColors.success 
                    : AppColors.warning,
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isConnectedToGitHub 
                  ? AppColors.success.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.link,
                size: 16,
                color: _isConnectedToGitHub 
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            tooltip: _isConnectedToGitHub ? 'Disconnect GitHub' : 'Connect GitHub',
          ),
          IconButton(
            onPressed: () {
              // TODO: Collaboration settings
            },
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _collaborationTabController,
          tabs: [
            Tab(text: 'Repository'),
            Tab(text: 'Pull Requests'),
            Tab(text: 'Issues'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      body: TabBarView(
        controller: _collaborationTabController,
        children: [
          _buildRepositoryTab(),
          _buildPullRequestsTab(),
          _buildIssuesTab(),
        ],
      ),
    );
  }

  Widget _buildRepositoryTab() {
    return _isConnectedToGitHub ? _buildConnectedRepository() : _buildConnectPrompt();
  }

  Widget _buildConnectPrompt() {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off,
                size: 40,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect to GitHub',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your GitHub account to access repositories, manage pull requests, and collaborate with your team.',
              textAlign: TextAlign.center,
              style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isConnectedToGitHub = true;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Successfully connected to GitHub!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(
                  Icons.link,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'Connect GitHub Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Show help or documentation
              },
              child: Text(
                'Need help connecting?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedRepository() {
    final brightness = Theme.of(context).brightness;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Repository info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient(brightness),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_open,
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
                          'warp-mobile-ai-ide',
                          style: TextStyle(
                            color: AppColors.titleText(brightness),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'getmad/warp-mobile-ai-ide',
                          style: TextStyle(
                            color: AppColors.bodyText(brightness),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Public',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mobile-first AI IDE bringing Warp + multi-model AI to iPhone and Android',
                style: TextStyle(
                  color: AppColors.bodyText(brightness),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildRepoStat(Icons.star, '⭐', '24'),
                  const SizedBox(width: 16),
                  _buildRepoStat(Icons.fork_right, '🔀', '7'),
                  const SizedBox(width: 16),
                  _buildRepoStat(Icons.bug_report, '🐛', '3'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Quick actions
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.upload,
                'Push Changes',
                'Upload your commits',
                AppColors.success,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📤 Changes pushed to remote'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.download,
                'Pull Changes',
                'Get latest updates',
                AppColors.info,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📥 Latest changes pulled'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Recent commits
        Text(
          'Recent Commits',
          style: TextStyle(
            color: AppColors.titleText(brightness),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildCommitItem(
          'Add AI integration foundation',
          'Set up basic AI service abstractions and OpenAI implementation',
          '2 hours ago',
          'getmad',
          '1a2b3c4',
        ),
        _buildCommitItem(
          'Create terminal interface with command processing',
          'Implemented basic terminal with Flutter, Git, and AI commands',
          '4 hours ago',
          'getmad',
          '5d6e7f8',
        ),
        _buildCommitItem(
          'Initial project setup and documentation',
          'Added README, ARCHITECTURE, and ROADMAP documentation',
          '6 hours ago',
          'getmad',
          '9g0h1i2',
        ),
      ],
    );
  }

  Widget _buildRepoStat(IconData icon, String emoji, String count) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
              color: AppColors.bodyText(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.bodyText(brightness),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitItem(String title, String description, String time, String author, String hash) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                author.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.titleText(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.bodyText(brightness),
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      author,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      hash,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPullRequestsTab() {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pull Requests',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Create new PR
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔄 Create PR feature coming soon!'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(Icons.add, color: AppColors.primary, size: 16),
              label: Text(
                'New',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
            ),
            const SizedBox(height: 16),
            
            _buildPRItem(
              'Feature: Add multi-model AI support',
              'Implement support for OpenAI, Claude, and Gemini models with fallback to on-device processing',
              'open',
              'feature/multi-ai-support',
              '12',
              '3',
              '2 days ago',
            ),
            _buildPRItem(
              'Fix: Terminal command history persistence',
              'Fix issue where terminal command history was not persisting across app restarts',
              'review',
              'fix/terminal-history',
              '8',
              '1',
              '1 day ago',
            ),
            _buildPRItem(
              'Enhancement: Mobile-optimized code editor',
              'Improve touch interactions, gesture support, and mobile-specific UI improvements',
              'merged',
              'enhancement/mobile-editor',
              '25',
              '7',
              '3 days ago',
            ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildPRItem(String title, String description, String status, String branch, 
                      String additions, String deletions, String time) {
    final brightness = Theme.of(context).brightness;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'open':
        statusColor = AppColors.success;
        statusText = 'Open';
        statusIcon = Icons.merge_type;
        break;
      case 'review':
        statusColor = AppColors.warning;
        statusText = 'Review';
        statusIcon = Icons.rate_review;
        break;
      case 'merged':
        statusColor = AppColors.primary;
        statusText = 'Merged';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusText = 'Draft';
        statusIcon = Icons.edit;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppColors.bodyText(brightness),
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                color: AppColors.editorBackground(brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  branch,
                  style: TextStyle(
                    color: AppColors.bodyText(brightness),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '+$additions',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-$deletions',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesTab() {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Issues',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Create new issue
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🐛 Create issue feature coming soon!'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(Icons.add, color: AppColors.primary, size: 16),
              label: Text(
                'New',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
            ),
            const SizedBox(height: 16),
            
            _buildIssueItem(
              'Bug: Terminal crashes on long output',
              'Terminal becomes unresponsive when displaying large amounts of output text',
              'bug',
              'high',
              '5',
              '2 days ago',
              true,
            ),
            _buildIssueItem(
              'Feature: Dark theme customization',
              'Allow users to customize dark theme colors and syntax highlighting',
              'enhancement',
              'medium',
              '12',
              '1 week ago',
              true,
            ),
            _buildIssueItem(
              'Documentation: Add API documentation',
              'Create comprehensive API documentation for AI service integrations',
              'documentation',
              'low',
              '3',
              '3 days ago',
              false,
            ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildIssueItem(String title, String description, String type, String priority, 
                        String comments, String time, bool isOpen) {
    final brightness = Theme.of(context).brightness;
    Color typeColor;
    Color priorityColor;
    
    switch (type) {
      case 'bug':
        typeColor = AppColors.error;
        break;
      case 'enhancement':
        typeColor = AppColors.success;
        break;
      case 'documentation':
        typeColor = AppColors.info;
        break;
      default:
        typeColor = AppColors.textTertiary;
    }

    switch (priority) {
      case 'high':
        priorityColor = AppColors.error;
        break;
      case 'medium':
        priorityColor = AppColors.warning;
        break;
      case 'low':
        priorityColor = AppColors.info;
        break;
      default:
        priorityColor = AppColors.textTertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen 
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.textTertiary.withValues(alpha: 0.3)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.error_outline : Icons.check_circle,
                color: isOpen ? AppColors.success : AppColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.comment,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                comments,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedState(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect to GitHub',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your account to access $feature',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}