import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/app_colors.dart';

/// Transizione tech personalizzata con effetti futuristici
/// Combina glitch, matrix dissolve, circuiti che si spengono e hologram
class TechPageTransition extends PageRouteBuilder {
  final Widget child;
  
  TechPageTransition({
    required this.child,
    Duration transitionDuration = const Duration(milliseconds: 1000),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _TechTransitionBuilder(
              animation: animation,
              child: child,
            );
          },
        );
}

/// Builder per la transizione tech con effetti multipli
class _TechTransitionBuilder extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;
  
  const _TechTransitionBuilder({
    required this.animation,
    required this.child,
  });

  @override
  State<_TechTransitionBuilder> createState() => _TechTransitionBuilderState();
}

class _TechTransitionBuilderState extends State<_TechTransitionBuilder>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _matrixController;
  late AnimationController _circuitController;
  late AnimationController _hologramController;
  
  late Animation<double> _glitchAnimation;
  late Animation<double> _matrixDissolveAnimation;
  late Animation<double> _circuitShutdownAnimation;
  late Animation<double> _hologramAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTransitionSequence();
  }

  void _setupAnimations() {
    // Glitch veloce (primi 150ms)
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Matrix dissolve più rapido (100ms - 300ms)
    _matrixController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Circuiti più veloci (200ms - 400ms)
    _circuitController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Hologram finale più rapido (350ms - 600ms)
    _hologramController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Animazioni specifiche
    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glitchController,
      curve: Curves.easeInOut,
    ));

    _matrixDissolveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _matrixController,
      curve: Curves.easeOut,
    ));

    _circuitShutdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _circuitController,
      curve: Curves.easeInOut,
    ));

    _hologramAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hologramController,
      curve: Curves.easeInOutCubic,
    ));

    // Animazioni per la nuova pagina - più veloci
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.05, // Meno zoom per effetto più sottile
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startTransitionSequence() async {
    // Feedback tattile iniziale più leggero
    HapticFeedback.lightImpact();
    
    // Sequenza rapida e simultanea per maggiore impatto
    Future.delayed(Duration.zero, () => _glitchController.forward());
    Future.delayed(const Duration(milliseconds: 100), () {
      _matrixController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _circuitController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      _hologramController.forward();
      HapticFeedback.mediumImpact(); // Unico feedback finale
    });
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _matrixController.dispose();
    _circuitController.dispose();
    _hologramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.animation,
        _glitchAnimation,
        _matrixDissolveAnimation,
        _circuitShutdownAnimation,
        _hologramAnimation,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Nuova pagina che entra
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            ),
            
            // Overlay effetti di transizione
            if (widget.animation.value < 0.9) ...[
              // Glitch overlay
              _buildGlitchOverlay(),
              
              // Matrix dissolve effect
              _buildMatrixDissolveEffect(),
              
              // Circuiti che si spengono
              _buildCircuitShutdownEffect(),
              
              // Effetto hologram finale
              _buildHologramEffect(),
              
              // Scanlines per effetto CRT
              _buildScanlineOverlay(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGlitchOverlay() {
    if (_glitchAnimation.value == 0.0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: GlitchOverlayPainter(
          _glitchAnimation.value,
          AppColors.techRedWithOpacity(0.8),
          AppColors.techBlueWithOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildMatrixDissolveEffect() {
    if (_matrixDissolveAnimation.value == 0.0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: MatrixDissolvePainter(
          _matrixDissolveAnimation.value,
          AppColors.techGreenWithOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildCircuitShutdownEffect() {
    if (_circuitShutdownAnimation.value == 0.0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: CircuitShutdownPainter(
          _circuitShutdownAnimation.value,
          AppColors.techBlueWithOpacity(0.8),
          AppColors.primaryWithOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildHologramEffect() {
    if (_hologramAnimation.value == 0.0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: HologramEffectPainter(
          _hologramAnimation.value,
          AppColors.primaryTintWithOpacity(0.6),
          AppColors.primaryWithOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildScanlineOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: TransitionScanlinePainter(
          widget.animation.value,
          AppColors.techGreenWithOpacity(0.1),
        ),
      ),
    );
  }
}

/// Painter per effetto glitch con distorsioni RGB
class GlitchOverlayPainter extends CustomPainter {
  final double animationValue;
  final Color redColor;
  final Color blueColor;
  
  GlitchOverlayPainter(this.animationValue, this.redColor, this.blueColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(456);

    // Intensità del glitch basata sull'animazione
    final glitchIntensity = math.sin(animationValue * math.pi);
    
    if (glitchIntensity > 0.3) {
      // Glitch blocks rossi
      for (int i = 0; i < 12; i++) {
        final blockHeight = random.nextDouble() * 20 + 5;
        final y = random.nextDouble() * (size.height - blockHeight);
        final offset = (random.nextDouble() - 0.5) * 15 * glitchIntensity;
        
        paint.color = redColor;
        canvas.drawRect(
          Rect.fromLTWH(offset, y, size.width, blockHeight),
          paint,
        );
      }
      
      // Glitch blocks blu
      for (int i = 0; i < 8; i++) {
        final blockHeight = random.nextDouble() * 15 + 3;
        final y = random.nextDouble() * (size.height - blockHeight);
        final offset = (random.nextDouble() - 0.5) * 10 * glitchIntensity;
        
        paint.color = blueColor;
        canvas.drawRect(
          Rect.fromLTWH(-offset, y, size.width, blockHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter per effetto matrix che si dissolve
class MatrixDissolvePainter extends CustomPainter {
  final double animationValue;
  final Color matrixColor;
  
  MatrixDissolvePainter(this.animationValue, this.matrixColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(789);
    
    const chars = '01110010';
    final dissolveProgress = animationValue;
    
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Opacità che diminuisce col progredire della dissoluzione
      final opacity = AppColors.safeOpacity((1.0 - dissolveProgress) * random.nextDouble());
      
      if (opacity > 0.05) {
        paint.color = matrixColor.withValues(alpha: opacity);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: chars[random.nextInt(chars.length)],
            style: TextStyle(
              color: paint.color,
              fontSize: 8 + random.nextDouble() * 6,
              fontFamily: 'Courier',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter per circuiti che si spengono progressivamente
class CircuitShutdownPainter extends CustomPainter {
  final double animationValue;
  final Color circuitColor;
  final Color nodeColor;
  
  CircuitShutdownPainter(this.animationValue, this.circuitColor, this.nodeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Progresso di spegnimento (inverso)
    final shutdownProgress = 1.0 - animationValue;
    
    // Linee orizzontali che si spengono
    for (int i = 0; i < 6; i++) {
      final y = (i + 1) * size.height / 7;
      final lineProgress = (shutdownProgress - i * 0.1).clamp(0.0, 1.0);
      
      if (lineProgress > 0) {
        final opacity = AppColors.safeOpacity(lineProgress * 0.8);
        paint.color = circuitColor.withValues(alpha: opacity);
        
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width * lineProgress, y),
          paint,
        );
        
        // Nodi sui circuiti
        if (lineProgress > 0.3) {
          paint.style = PaintingStyle.fill;
          paint.color = nodeColor.withValues(alpha: opacity);
          canvas.drawCircle(
            Offset(size.width * lineProgress * 0.8, y),
            2,
            paint,
          );
          paint.style = PaintingStyle.stroke;
        }
      }
    }
    
    // Linee verticali
    for (int i = 0; i < 4; i++) {
      final x = (i + 1) * size.width / 5;
      final lineProgress = (shutdownProgress - 0.2 - i * 0.15).clamp(0.0, 1.0);
      
      if (lineProgress > 0) {
        final opacity = AppColors.safeOpacity(lineProgress * 0.6);
        paint.color = circuitColor.withValues(alpha: opacity);
        
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height * lineProgress),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter per effetto hologram di transizione
class HologramEffectPainter extends CustomPainter {
  final double animationValue;
  final Color hologramColor;
  final Color coreColor;
  
  HologramEffectPainter(this.animationValue, this.hologramColor, this.coreColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Effetto hologram che si espande dal centro
    final radius = animationValue * size.width * 0.8;
    final opacity = AppColors.safeOpacity((1.0 - animationValue) * 0.8);
    
    // Anelli concentrici
    for (int i = 0; i < 5; i++) {
      final ringRadius = radius - (i * 40);
      if (ringRadius > 0) {
        final ringOpacity = AppColors.safeOpacity(opacity * (5 - i) / 5);
        paint.strokeWidth = 2.0 - (i * 0.3);
        paint.color = hologramColor.withValues(alpha: ringOpacity);
        
        canvas.drawCircle(center, ringRadius, paint);
      }
    }
    
    // Linee di scansione radiali
    paint.strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animationValue * math.pi * 2);
      final lineOpacity = AppColors.safeOpacity(opacity * 0.6);
      paint.color = coreColor.withValues(alpha: lineOpacity);
      
      final endPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawLine(center, endPoint, paint);
    }
    
    // Core centrale pulsante
    if (animationValue > 0.5) {
      final coreOpacity = AppColors.safeOpacity(opacity * 1.2);
      paint.style = PaintingStyle.fill;
      paint.color = coreColor.withValues(alpha: coreOpacity);
      canvas.drawCircle(center, 8 + math.sin(animationValue * math.pi * 4) * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter per scanlines durante la transizione
class TransitionScanlinePainter extends CustomPainter {
  final double animationValue;
  final Color scanlineColor;
  
  TransitionScanlinePainter(this.animationValue, this.scanlineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Scanlines che si muovono verso il basso
    final scanPosition = animationValue * size.height * 2;
    
    for (int i = 0; i < size.height.toInt(); i += 3) {
      final lineY = i.toDouble();
      final distanceFromScan = (lineY - scanPosition).abs();
      final opacity = AppColors.safeOpacity(
        math.max(0, 0.15 - (distanceFromScan / 100))
      );
      
      if (opacity > 0.01) {
        paint.color = scanlineColor.withValues(alpha: opacity);
        canvas.drawRect(
          Rect.fromLTWH(0, lineY, size.width, 1),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}