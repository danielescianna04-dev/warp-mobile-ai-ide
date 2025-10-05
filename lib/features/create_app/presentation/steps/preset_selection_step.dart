import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/wizard/preset_apps.dart';
import '../../providers/create_app_wizard_provider.dart';

/// Step per la selezione di un preset di app predefinito con design minimalista
class PresetSelectionStep extends StatefulWidget {
  const PresetSelectionStep({super.key});

  @override
  State<PresetSelectionStep> createState() => _PresetSelectionStepState();
}

class _PresetSelectionStepState extends State<PresetSelectionStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  PresetAppType? _selectedPreset;

  @override
  void initState() {
    super.initState();
    
    // Animazioni più semplici e eleganti
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Inizia l'animazione
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePresetSelection(PresetAppType presetType) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = presetType;
    });
    
    // Applica la selezione al provider
    context.read<CreateAppWizardProvider>().selectPreset(presetType);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final presetApps = PresetAppsRepository.getPresetApps();
    final customPreset = PresetAppsRepository.getCustomPreset();
    final allPresets = [...presetApps, customPreset];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header minimalista
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titolo principale
                        Text(
                          'Describe your app idea...',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: isDark ? const Color(0xFFE1E1E6) : const Color(0xFF1A1A1D),
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista verticale dei preset
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: allPresets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 1),
                      itemBuilder: (context, index) {
                        final config = allPresets[index];
                        final isSelected = _selectedPreset == config.type;
                        
                        return _buildPresetItem(
                          config: config,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => _handlePresetSelection(config.type),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPresetItem({
    required PresetAppConfig config,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? const Color(0xFF2A2A2E)
                      : const Color(0xFFE5E5E5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    config.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDark 
                          ? const Color(0xFFE1E1E6)
                          : const Color(0xFF1A1A1D),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Indicatore di selezione minimalista
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark 
                          ? Colors.white
                          : Colors.black,
                    ),
                  )
                else
                  const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
