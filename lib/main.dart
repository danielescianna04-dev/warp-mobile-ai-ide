import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'features/warp_terminal/presentation/pages/warp_terminal_page.dart';
import 'shared/constants/app_colors.dart';
import 'core/ai/ai_manager.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AI Manager
  try {
    await AIManager.instance.initialize();
    debugPrint('✅ AI services initialized successfully');
  } catch (e) {
    debugPrint('⚠️ AI services initialization failed: $e');
    // Continue running the app even if AI services fail
  }
  
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
      home: const WarpTerminalPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
