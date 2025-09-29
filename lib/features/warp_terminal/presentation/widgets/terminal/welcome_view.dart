import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/constants/app_colors.dart';
import '../../../../../shared/widgets/hero_background.dart';

/// Welcome View aggiornata per VibeCode Minimal Purple
/// Con HeroBackground adattivo e stile Apple-like
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WelcomeHeroBackground(
      showBrandInfo: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeroIcon(context),
                  const SizedBox(height: 32),
                  _buildTitle(context),
                  const SizedBox(height: 12),
                  _buildSubtitle(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _scaleController.reset();
        _scaleController.forward();
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          // Usa i nuovi colori brand IDENTICI
          gradient: LinearGradient(
            colors: const [
              AppColors.primary,      // #6F5CFF
              AppColors.primaryShade, // #5946D6
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppColors.primaryTint.withValues(alpha: 0.15),
              blurRadius: 45,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.terminal_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Drape',
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Mobile-first AI IDE\ncon supporto multi-model',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Multi-AI',
        'subtitle': 'Claude, GPT, Gemini',
      },
      {
        'icon': Icons.code,
        'title': 'Terminal',
        'subtitle': 'Comandi avanzati',
      },
      {
        'icon': Icons.palette,
        'title': 'Themes',
        'subtitle': 'Light & Dark',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.map((feature) {
        return _buildFeatureCard(
          context,
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['subtitle'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
