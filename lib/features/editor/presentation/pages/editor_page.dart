import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _codeController = TextEditingController(
    text: '''// Welcome to Warp Mobile AI IDE! 🚀
// Start coding with AI assistance

void main() {
  print('Hello, Mobile Developer!');
  
  // AI-powered features coming soon:
  // • Code completion
  // • Code explanation
  // • Bug fixing
  // • Refactoring suggestions
}

class WarpMobileIDE {
  final String version = '1.0.0';
  final bool isAwesome = true;
  
  void startCoding() {
    print("Let's build amazing mobile apps!");
  }
}''',
  );

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getEditorBackground(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.code,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'main.dart',
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
              // TODO: Implement AI assistance
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('AI assistance coming soon! 🤖'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            tooltip: 'Ask AI',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement file operations
            },
            icon: Icon(
              Icons.save,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            tooltip: 'Save',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement settings
            },
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // File tabs (placeholder)
          Container(
            height: 40,
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFileTab('main.dart', true),
                _buildFileTab('utils.dart', false),
                _buildFileTab('models.dart', false),
              ],
            ),
          ),
          // Code editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers
                  SizedBox(
                    width: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        _codeController.text.split('\n').length,
                        (index) => Container(
                          height: 20,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.getEditorLineNumbers(context),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Code input
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Start typing code...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status bar
          Container(
            height: 32,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  'Dart',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'UTF-8',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Implement AI chat
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI Chat coming soon! 💬'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.smart_toy,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFileTab(String fileName, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.background : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isActive
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code_outlined,
            size: 12,
            color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            fileName,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}
