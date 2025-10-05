import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../providers/create_app_wizard_provider.dart';
import '../steps/name_step.dart';
import '../steps/app_type_step.dart';
import '../steps/framework_step.dart';
import '../steps/features_step.dart';
import '../steps/template_step.dart';
import '../steps/summary_step.dart';

class CreateAppWizardPage extends StatefulWidget {
  const CreateAppWizardPage({super.key});

  @override
  State<CreateAppWizardPage> createState() => _CreateAppWizardPageState();
}

class _CreateAppWizardPageState extends State<CreateAppWizardPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateAppWizardProvider(),
      child: Consumer<CreateAppWizardProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background(Theme.of(context).brightness),
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(provider),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // Background gradient
                  _buildBackground(),
                  
                  // Main content
                  SafeArea(
                    child: Column(
                      children: [
                        // Progress indicator
                        _buildProgressIndicator(provider),
                        
                        // Step content
                        Expanded(
                          child: _buildStepContent(provider),
                        ),
                        
                        // Navigation buttons
                        _buildNavigationButtons(provider),
                      ],
                    ),
                  ),
                  
                  // Loading overlay
                  if (provider.isGenerating) _buildLoadingOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: provider.isGenerating ? null : () => _handleClose(provider),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.currentStepTitle,
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (provider.currentStepDescription.isNotEmpty)
            Text(
              provider.currentStepDescription,
              style: TextStyle(
                color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        // Quick setup menu
        PopupMenuButton<String>(
          enabled: !provider.isGenerating,
          onSelected: (value) => _handleQuickSetup(provider, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'flutter',
              child: Row(
                children: [
                  Text('🚀', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Flutter Mobile', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'react',
              child: Row(
                children: [
                  Text('⚛️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('React Web', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'electron',
              child: Row(
                children: [
                  Text('🖥️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Electron Desktop', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.flash_on_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient(brightness),
      ),
    );
  }

  Widget _buildProgressIndicator(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: MediaQuery.of(context).size.width * provider.progress,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(CreateAppWizardProvider provider) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        // This won't be called since physics is disabled
        // Navigation is handled by provider methods
      },
      children: [
        // Step 0: Preset selection (era NameStep)
        const NameStep(),
        // Step 1: Nome app quando custom è selezionato, o salta al summary per preset
        provider.wizardData.isCustomFlow 
            ? const AppTypeStep()
            : const SummaryStep(), // Vai direttamente al summary per preset
        const FrameworkStep(),
        const FeaturesStep(),
        const TemplateStep(),
        const SummaryStep(),
      ],
    );
  }

  Widget _buildNavigationButtons(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark 
                ? const Color(0xFF000000).withValues(alpha: 0.85)
                : const Color(0xFFFAFAFA).withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.1],
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator più piccolo
                _buildCompactProgressIndicator(provider, isDark),
                
                const SizedBox(height: 8),
                
                // Pulsante di navigazione più piccolo
                _buildCompactNavigationButton(provider, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface(Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Creazione progetto in corso...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Questo potrebbe richiedere alcuni minuti',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack(CreateAppWizardProvider provider) {
    HapticFeedback.lightImpact();
    provider.previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleNext(CreateAppWizardProvider provider) {
    HapticFeedback.lightImpact();
    
    if (provider.isLastStep) {
      _handleCreateApp(provider);
    } else {
      final currentStep = provider.currentStep;
      provider.nextStep();
      
      // Calcola lo step di destinazione
      int targetStep = provider.currentStep;
      
      // Se abbiamo selezionato un preset e siamo al step 1, salta al summary
      if (currentStep == 1 && 
          provider.wizardData.isPresetSelected && 
          targetStep == CreateAppWizardProvider.totalSteps - 1) {
        // Animazione diretta al summary (step 5)
        _pageController.animateToPage(
          targetStep,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Navigazione normale
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  Future<void> _handleCreateApp(CreateAppWizardProvider provider) async {
    try {
      await provider.generateProject();
      
      if (mounted) {
        // Show success and navigate to terminal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Progetto "${provider.wizardData.appName}" creato con successo!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface(Theme.of(context).brightness),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Navigate back and potentially open terminal
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Errore durante la creazione: ${error.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _handleClose(CreateAppWizardProvider provider) {
    if (provider.currentStep > 0) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface(Theme.of(context).brightness),
          title: Text(
            'Uscire dal wizard?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'I dati inseriti verranno persi.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Esci', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildCompactProgressIndicator(CreateAppWizardProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icona più piccola
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              provider.isLastStep
                  ? Icons.rocket_launch_rounded
                  : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Testo del progresso più piccolo
          Text(
            '${provider.currentStep + 1}/${CreateAppWizardProvider.totalSteps}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Barra di progresso più piccola
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: 40 * provider.progress,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNavigationButton(CreateAppWizardProvider provider, bool isDark) {
    final isEnabled = provider.isCurrentStepValid && !provider.isGenerating;
    final isLastStep = provider.isLastStep;
    final buttonText = isLastStep ? 'Crea' : 'Avanti';
    final buttonIcon = isLastStep 
        ? Icons.rocket_launch_rounded 
        : Icons.arrow_forward_rounded;
    
    return Row(
      children: [
        // Pulsante Indietro compatto (se disponibile)
        if (provider.canGoBack && !provider.isGenerating)
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _handleBack(provider),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A).withValues(alpha: 0.7)
                      : const Color(0xFFE8E8E8).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF404040)
                        : const Color(0xFFD0D0D0),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Indietro',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        if (provider.canGoBack && !provider.isGenerating)
          const SizedBox(width: 8),
        
        // Pulsante principale compatto
        Expanded(
          flex: provider.canGoBack ? 2 : 3,
          child: InkWell(
            onTap: isEnabled ? () => _handleNext(provider) : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(
                vertical: 10, 
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: isLastStep
                            ? [
                                const Color(0xFF6C5CE7),
                                const Color(0xFF74B9FF),
                              ]
                            : [
                                AppColors.primary,
                                AppColors.primaryTint,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8)),
                          (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDDDDD)),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEnabled
                      ? (isLastStep
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.2))
                      : Colors.transparent,
                  width: 0.5,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: isLastStep
                              ? const Color(0xFF6C5CE7).withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isGenerating)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      buttonIcon,
                      color: isEnabled 
                          ? Colors.white 
                          : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                      size: 16,
                    ),
                  
                  const SizedBox(width: 4),
                  
                  Flexible(
                    child: Text(
                      provider.isGenerating 
                          ? (isLastStep ? 'Creando...' : 'Loading...')
                          : buttonText,
                      style: TextStyle(
                        color: isEnabled 
                            ? Colors.white 
                            : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (isLastStep && isEnabled && !provider.isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('🚀', style: TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleQuickSetup(CreateAppWizardProvider provider, String type) {
    HapticFeedback.lightImpact();
    
    switch (type) {
      case 'flutter':
        provider.setupFlutterMobileApp();
        break;
      case 'react':
        provider.setupReactWebApp();
        break;
      case 'electron':
        provider.setupElectronDesktopApp();
        break;
    }
    
    // Go to the last step to review
    provider.goToStep(CreateAppWizardProvider.totalSteps - 1);
    _pageController.animateToPage(
      CreateAppWizardProvider.totalSteps - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}