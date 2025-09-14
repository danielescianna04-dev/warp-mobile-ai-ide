import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/editor/presentation/pages/editor_page.dart';
import 'features/terminal/presentation/pages/terminal_page.dart';
import 'features/collaboration/presentation/pages/collaboration_page.dart';
import 'features/preview/presentation/pages/preview_page.dart';
import 'shared/constants/app_colors.dart';

void main() {
  runApp(const WarpMobileAIIDE());
}

class WarpMobileAIIDE extends StatelessWidget {
  const WarpMobileAIIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warp Mobile AI IDE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'JetBrains Mono',
      ),
      home: const MainNavigationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.code,
      label: 'Editor',
      page: const EditorPage(),
    ),
    NavigationItem(
      icon: Icons.terminal,
      label: 'Terminal',
      page: const TerminalPage(),
    ),
    NavigationItem(
      icon: Icons.phone_android,
      label: 'Preview',
      page: const PreviewPage(),
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Collab',
      page: const CollaborationPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _navigationItems.length,
      vsync: this,
    );
    
    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: _navigationItems.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _selectedIndex;
                
                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected 
                            ? AppColors.primary
                            : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected 
                              ? AppColors.primary
                              : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected 
                              ? FontWeight.w600
                              : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}
