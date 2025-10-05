import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/wizard/preset_apps.dart';
import '../../providers/create_app_wizard_provider.dart';

/// Primo step del wizard con design minimalista per selezione preset
class NameStep extends StatefulWidget {
  const NameStep({super.key});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _ideaController;
  late FocusNode _ideaFocusNode;
  
  PresetAppType? _selectedPreset;
  String _userIdea = '';

  @override
  void initState() {
    super.initState();
    
    // Controllers per input
    _ideaController = TextEditingController();
    _ideaFocusNode = FocusNode();
    
    // Animazioni eleganti
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
    _ideaController.dispose();
    _ideaFocusNode.dispose();
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
  
  void _handleIdeaChange(String value) {
    setState(() {
      _userIdea = value;
    });
    // Aggiorna il provider con l'idea dell'utente (usa il campo appName temporaneamente)
    context.read<CreateAppWizardProvider>().updateAppName(value);
  }
  
  Widget _buildIdeaInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A1A1E).withValues(alpha: 0.8)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ideaFocusNode.hasFocus
              ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF6366F1))
              : (isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E5E5)),
          width: _ideaFocusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _ideaController,
        focusNode: _ideaFocusNode,
        maxLines: 3,
        style: TextStyle(
          color: isDark ? const Color(0xFFE1E1E6) : const Color(0xFF1A1A1D),
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'es. Un\'app per organizzare le ricette della nonna, condividerle con la famiglia e scoprire nuove ricette in base agli ingredienti disponibili...',
          hintStyle: TextStyle(
            color: isDark 
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
            fontSize: 16,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: _handleIdeaChange,
        textInputAction: TextInputAction.done,
      ),
    );
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
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con campo di input
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                            const SizedBox(height: 20),
                            
                            // Campo di input per l'idea
                            _buildIdeaInput(isDark),
                          ],
                        ),
                      ),

                      // Lista verticale dei preset - occupa tutto lo spazio rimanente
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120), // Padding bottom per il pulsante
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
              ),
            );
          },
        ),
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
