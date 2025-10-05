import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/wizard/preset_apps.dart';

/// Card interattiva per la selezione dei preset di app
class PresetCard extends StatefulWidget {
  final PresetAppConfig config;
  final bool isSelected;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const PresetCard({
    super.key,
    required this.config,
    required this.isSelected,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  State<PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<PresetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PresetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Anima quando lo stato di selezione cambia
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.94 : _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Ombra principale
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  // Ombra di selezione con colore del preset
                  if (widget.isSelected)
                    BoxShadow(
                      color: widget.config.accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  // Glow effect animato
                  if (_glowAnimation.value > 0)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _glowAnimation.value * 0.2),
                      blurRadius: 15 * _glowAnimation.value,
                      offset: Offset.zero,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background con gradiente
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(brightness),
                          // Gradient overlay leggero per i preset selezionati
                          gradient: widget.isSelected 
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.config.accentColor.withValues(alpha: 0.08),
                                    widget.config.accentColor.withValues(alpha: 0.04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.3, 1.0],
                                )
                              : null,
                        ),
                      ),
                    ),
                    
                    // Bordo animato per la selezione
                    if (widget.isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.config.accentColor.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    // Contenuto della card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con icona e badge di selezione
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icona con sfondo colorato
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: widget.config.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: widget.config.accentColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  widget.config.icon,
                                  color: widget.config.accentColor,
                                  size: 20,
                                ),
                              ),
                              
                              // Checkmark per la selezione
                              if (widget.isSelected)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: widget.config.accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.config.accentColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Titolo
                          Text(
                            widget.config.name,
                            style: TextStyle(
                              color: AppColors.titleText(brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Descrizione
                          Expanded(
                            child: Text(
                              widget.config.description,
                              style: TextStyle(
                                color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Framework badge (solo per preset non custom)
                          if (widget.config.type != PresetAppType.custom) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.config.framework.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Overlay di pressione
                    if (_isPressed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}