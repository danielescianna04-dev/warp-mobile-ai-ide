import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../warp_terminal/presentation/pages/warp_terminal_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startMinimalSequence();
  }

  void _setupAnimations() {
    // Logo controller - breathing effect minimal
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Testo fade semplice
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo breathing: scale da 0.95 a 1.05 e ritorno
    _logoScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Glow che pulsa delicatamente
    _logoGlowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Testo fade in semplice
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
  }

  void _startMinimalSequence() async {
    // Feedback tattile leggero
    HapticFeedback.lightImpact();

    // Logo breathing inizia subito (effetto repeat per pulsazione continua)
    _logoController.repeat(reverse: true);
    
    // Testo appare dopo 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      _textController.forward();
    });

    // Naviga dopo solo 1 secondo con transizione fade semplice
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WarpTerminalPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Background pulito che si adatta al tema
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.getBackground(context)
        : Colors.white;
        
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo breathing minimal
            _buildMinimalLogo(),
            
            const SizedBox(height: 32),
            
            // Testo fade semplice
            _buildMinimalText(),
          ],
        ),
      ),
    );
  }


  Widget _buildMinimalLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScaleAnimation, _logoGlowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: _logoGlowAnimation.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _logoGlowAnimation.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                painter: DrapeLogoPainter(
                  _logoGlowAnimation.value,
                  AppColors.primary,
                  AppColors.primaryTint,
                ),
                size: const Size(60, 60),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalText() {
    return AnimatedBuilder(
      animation: _textFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value,
          child: Column(
            children: [
              Text(
                'DRAPE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mobile AI IDE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.getTitleText(context).withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Matrix effect painter
class MatrixPainter extends CustomPainter {
  final double animationValue;
  MatrixPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(123);
    
    const chars = '01ABCDEF{}[]<>/\\|';
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + animationValue * size.height * 2) % (size.height + 100);
      
      final opacity = AppColors.safeOpacity(1.0 - (y / size.height));
      paint.color = AppColors.techGreenWithOpacity(opacity * 0.3);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: chars[random.nextInt(chars.length)],
          style: TextStyle(
            color: paint.color,
            fontSize: 12,
            fontFamily: 'Courier',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y - 50));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Logo painter per DRAPE - Design minimal e unico
class DrapeLogoPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color accentColor;
  
  DrapeLogoPainter(this.animationValue, this.primaryColor, this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    final center = Offset(size.width / 2, size.height / 2);
    final logoSize = size.width * 0.8;
    final opacity = AppColors.safeOpacity(animationValue);
    
    // === ELEMENTO 1: "D" stilizzato come diamante tech ===
    final diamondPath = Path();
    final diamondSize = logoSize * 0.3;
    diamondPath.moveTo(center.dx - diamondSize/2, center.dy);
    diamondPath.lineTo(center.dx, center.dy - diamondSize/2);
    diamondPath.lineTo(center.dx + diamondSize/2, center.dy);
    diamondPath.lineTo(center.dx, center.dy + diamondSize/2);
    diamondPath.close();
    
    // Bordo esterno del diamante
    paint.strokeWidth = 2.5;
    paint.color = primaryColor.withValues(alpha: opacity);
    canvas.drawPath(diamondPath, paint);
    
    // Riempimento con gradiente simulato
    paint.style = PaintingStyle.fill;
    paint.color = primaryColor.withValues(alpha: opacity * 0.15);
    canvas.drawPath(diamondPath, paint);
    
    // === ELEMENTO 2: Linee di connessione AI (rappresentano "R", "A", "P", "E") ===
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.8;
    paint.color = accentColor.withValues(alpha: opacity * 0.8);
    
    // Linea "R" - arco superiore destro
    final rPath = Path();
    rPath.moveTo(center.dx + diamondSize/3, center.dy - diamondSize/3);
    rPath.quadraticBezierTo(
      center.dx + logoSize/2.2, 
      center.dy - logoSize/2.5,
      center.dx + logoSize/2.2, 
      center.dy - diamondSize/6
    );
    canvas.drawPath(rPath, paint);
    
    // Linea "A" - triangolo minimale sinistra
    final aPath = Path();
    aPath.moveTo(center.dx - diamondSize/3, center.dy - diamondSize/3);
    aPath.lineTo(center.dx - logoSize/2.2, center.dy - logoSize/3.5);
    aPath.lineTo(center.dx - logoSize/2.5, center.dy);
    canvas.drawPath(aPath, paint);
    
    // Linea "P" - doppia linea verticale destra  
    canvas.drawLine(
      Offset(center.dx + diamondSize/3, center.dy + diamondSize/6),
      Offset(center.dx + logoSize/2.2, center.dy + logoSize/3),
      paint,
    );
    
    // Linea "E" - tre tratti orizzontali sotto
    paint.strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final lineY = center.dy + diamondSize/3 + (i * diamondSize/8);
      canvas.drawLine(
        Offset(center.dx - logoSize/3.5, lineY),
        Offset(center.dx + logoSize/3.5, lineY),
        paint,
      );
    }
    
    // === ELEMENTO 3: Pulsazione centrale (rappresenta AI) ===
    if (animationValue > 0.3) {
      final pulseRadius = (8 + math.sin(animationValue * math.pi * 4) * 3) * animationValue;
      paint.style = PaintingStyle.fill;
      paint.color = primaryColor.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(center, pulseRadius, paint);
      
      // Anello esterno pulsante
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;
      paint.color = accentColor.withValues(alpha: opacity * 0.4);
      canvas.drawCircle(center, pulseRadius + 6, paint);
    }
    
    // === ELEMENTO 4: Particelle orbitali (tech/AI) ===
    if (animationValue > 0.5) {
      paint.style = PaintingStyle.fill;
      for (int i = 0; i < 6; i++) {
        final angle = (animationValue * 2 * math.pi * 0.7) + (i * math.pi / 3);
        final orbitRadius = logoSize * 0.4;
        final particleX = center.dx + math.cos(angle) * orbitRadius;
        final particleY = center.dy + math.sin(angle) * orbitRadius;
        
        final particleOpacity = AppColors.safeOpacity(opacity * (0.3 + 0.4 * math.sin(animationValue * 3 + i)));
        paint.color = i.isEven 
            ? primaryColor.withValues(alpha: particleOpacity)
            : accentColor.withValues(alpha: particleOpacity);
        
        canvas.drawCircle(
          Offset(particleX, particleY),
          2.0 + math.sin(animationValue * 4 + i) * 0.5,
          paint,
        );
      }
    }
    
    // === ELEMENTO 5: Effetto hologram border ===
    if (animationValue > 0.7) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.8;
      final hologramOpacity = AppColors.safeOpacity((animationValue - 0.7) * 2);
      paint.color = accentColor.withValues(alpha: hologramOpacity * 0.3);
      
      // Bordo ottagonale minimal
      final octPath = Path();
      const sides = 8;
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * math.pi / sides) - math.pi / 2;
        final x = center.dx + math.cos(angle) * (logoSize * 0.5);
        final y = center.dy + math.sin(angle) * (logoSize * 0.5);
        
        if (i == 0) {
          octPath.moveTo(x, y);
        } else {
          octPath.lineTo(x, y);
        }
      }
      octPath.close();
      canvas.drawPath(octPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Circuit painter
class CircuitPainter extends CustomPainter {
  final double animationValue;
  CircuitPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Circuiti orizzontali
    for (int i = 0; i < 8; i++) {
      final y = (i + 1) * size.height / 9;
      final progress = (animationValue - i * 0.1).clamp(0.0, 1.0);
      
      paint.color = AppColors.techBlueWithOpacity(progress * 0.6);
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
      
      // Nodi dei circuiti
      if (progress > 0.5) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(size.width * progress, y),
          3,
          paint,
        );
        paint.style = PaintingStyle.stroke;
      }
    }

    // Circuiti verticali
    for (int i = 0; i < 6; i++) {
      final x = (i + 1) * size.width / 7;
      final progress = (animationValue - 0.3 - i * 0.1).clamp(0.0, 1.0);
      
      paint.color = AppColors.techGreenWithOpacity(progress * 0.4);
      
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Scanline painter
class ScanlinePainter extends CustomPainter {
  final double animationValue;
  ScanlinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < size.height.toInt(); i += 4) {
      paint.color = AppColors.techGreenWithOpacity(0.03);
      canvas.drawRect(
        Rect.fromLTWH(0, i.toDouble(), size.width, 1),
        paint,
      );
    }
    
    // Scanning line
    final scanY = animationValue * size.height;
    paint.color = AppColors.techGreenWithOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 2, size.width, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Scrolling code painter
class ScrollingCodePainter extends CustomPainter {
  final double animationValue;
  ScrollingCodePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final codeLines = [
      'import flutter/material.dart',
      'class DrapeIDE extends StatefulWidget',
      'Widget build(BuildContext context)',
      'return Scaffold(body: Terminal())',
      'void executeCommand(String cmd)',
      'final result = await process.run()',
      'if (result.exitCode == 0) {',
      '  print("Success: \${result.stdout}");',
      '} else {',
      '  print("Error: \${result.stderr}");',
      '}',
    ];
    
    for (int i = 0; i < codeLines.length; i++) {
      final y = (i * 30 + animationValue * 300) % (size.height + 100);
      paint.color = AppColors.techBlueWithOpacity(0.3);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: codeLines[i],
          style: TextStyle(
            color: paint.color,
            fontSize: 10,
            fontFamily: 'Courier',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y - 50));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Tech grid painter per il logo
class TechGridPainter extends CustomPainter {
  final double animationValue;
  TechGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.techGreenWithOpacity(animationValue * 0.3);

    // Griglia
    for (int i = 0; i <= 10; i++) {
      final x = i * size.width / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      
      final y = i * size.height / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Tech particles painter
class TechParticlesPainter extends CustomPainter {
  final double animationValue;
  TechParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 4);
      final radius = 50 + math.sin(animationValue * 3 + i) * 10;
      final particleSize = 2 + math.sin(animationValue * 4 + i);
      
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      paint.color = AppColors.primaryTintWithOpacity(0.8);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
      
      // Connections
      if (i > 0) {
        final prevAngle = (animationValue * 2 * math.pi) + ((i - 1) * math.pi / 4);
        final prevX = center.dx + math.cos(prevAngle) * radius;
        final prevY = center.dy + math.sin(prevAngle) * radius;
        
        paint.strokeWidth = 1;
        paint.style = PaintingStyle.stroke;
        paint.color = AppColors.primaryWithOpacity(0.3);
        canvas.drawLine(Offset(x, y), Offset(prevX, prevY), paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
