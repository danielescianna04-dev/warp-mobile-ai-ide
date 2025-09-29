import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Widget per applicare il background hero con gradiente adattivo
/// Implementa le specifiche VibeCode Minimal Purple per Light e Dark Mode
class HeroBackground extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final AlignmentGeometry? gradientCenter;
  final double? gradientRadius;
  
  const HeroBackground({
    super.key,
    required this.child,
    this.enabled = true,
    this.gradientCenter,
    this.gradientRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final brightness = Theme.of(context).brightness;
    
    return Container(
      decoration: BoxDecoration(
        gradient: _getHeroGradient(brightness),
      ),
      child: child,
    );
  }

  /// Ottieni il gradiente hero corretto basato sulla brightness
  Gradient _getHeroGradient(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        // Gradiente lineare diagonale soft per light mode
        return LinearGradient(
          begin: const Alignment(-0.8, -1.0), // Inizia dall'alto-sinistra
          end: const Alignment(0.8, 1.0),     // Finisce in basso-destra
          colors: [
            AppColors.primaryTint.withValues(alpha: 0.15),   // Viola soft
            AppColors.primary.withValues(alpha: 0.08),       // Viola leggero
            AppColors.lightBackground,                        // Bianco pulito
            AppColors.lightBackground,                        // Bianco pulito
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );
        
      case Brightness.dark:
        // Gradiente lineare diagonale soft per dark mode
        return LinearGradient(
          begin: const Alignment(-0.6, -1.0), // Inizia dall'alto-sinistra
          end: const Alignment(1.0, 0.8),     // Finisce in basso-destra
          colors: [
            AppColors.primaryShade.withValues(alpha: 0.08),  // Viola scuro molto soft
            AppColors.primary.withValues(alpha: 0.04),       // Viola appena percettibile
            AppColors.darkBackground,                         // Nero profondo
            AppColors.darkBackground,                         // Nero profondo
          ],
          stops: const [0.0, 0.35, 0.8, 1.0],
        );
    }
  }
}

/// Widget specializzato per welcome/landing pages
class WelcomeHeroBackground extends StatelessWidget {
  final Widget child;
  final bool showBrandInfo;
  
  const WelcomeHeroBackground({
    super.key,
    required this.child,
    this.showBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hero gradient background - versione extra soft per welcome
        HeroBackground(
          gradientCenter: const Alignment(0.0, -0.8), // Più in alto per welcome
          gradientRadius: 1.8, // Più ampio e disperso
          child: child,
        ),
        
        // Brand info overlay opzionale
        if (showBrandInfo)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 20,
            child: _buildBrandInfoCard(context),
          ),
      ],
    );
  }
  
  Widget _buildBrandInfoCard(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'VibeCore',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${brightness.name.toUpperCase()} MODE',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Brand colors preview
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _colorDot(AppColors.primary),
              const SizedBox(width: 3),
              _colorDot(AppColors.primaryTint),
              const SizedBox(width: 3),
              _colorDot(AppColors.primaryShade),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _colorDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
    );
  }
}

/// Widget per animated hero background con effetti di parallasse
class AnimatedHeroBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enableParallax;
  
  const AnimatedHeroBackground({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 10),
    this.enableParallax = false,
  });

  @override
  State<AnimatedHeroBackground> createState() => _AnimatedHeroBackgroundState();
}

class _AnimatedHeroBackgroundState extends State<AnimatedHeroBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<AlignmentGeometry> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _gradientAnimation = AlignmentTween(
      begin: const Alignment(0.0, -0.8),
      end: const Alignment(0.0, -0.4),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return HeroBackground(
          gradientCenter: _gradientAnimation.value,
          gradientRadius: 1.3,
          child: widget.child,
        );
      },
    );
  }
}

/// Extension helper per context
extension HeroBackgroundExtension on BuildContext {
  /// Quick access al gradiente hero corretto
  RadialGradient get heroGradient => AppColors.heroGradient(
    Theme.of(this).brightness,
  );
  
  /// Check se è in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Check se è in light mode  
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;
}