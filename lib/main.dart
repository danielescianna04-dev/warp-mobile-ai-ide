import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'shared/constants/app_colors.dart';
import 'shared/constants/app_theme.dart';
import 'shared/providers/theme_provider.dart';
import 'core/ai/ai_manager.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Imposta orientamento solo portrait per un'esperienza mobile ottimale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize AI Manager
  try {
    await AIManager.instance.initialize();
    debugPrint('✅ AI services initialized successfully');
  } catch (e) {
    debugPrint('⚠️ AI services initialization failed: $e');
    // Continue running the app even if AI services fail
  }
  
  runApp(const DrapeApp());
}

class DrapeApp extends StatelessWidget {
  const DrapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Drape',
            // ===== VIBECORE MINIMAL PURPLE THEMES =====
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            // Inizia con la splash screen spettacolare
            home: const SplashPage(),
            // Log tema attivo per debug
            builder: (context, child) {
              if (kDebugMode) {
                final brightness = Theme.of(context).brightness;
                debugPrint('🎨 VibeCode Theme Active: ${brightness.name.toUpperCase()}');
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}
