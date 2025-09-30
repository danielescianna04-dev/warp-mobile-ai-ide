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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: MediaQuery.of(context).size.width * provider.progress,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient(brightness),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(CreateAppWizardProvider.totalSteps, (index) {
              final isActive = index == provider.currentStep;
              final isCompleted = index < provider.currentStep;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.success
                            : AppColors.surface(brightness).withValues(alpha: 0.4),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
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
      children: const [
        NameStep(),
        AppTypeStep(), 
        FrameworkStep(),
        FeaturesStep(),
        TemplateStep(),
        SummaryStep(),
      ],
    );
  }

  Widget _buildNavigationButtons(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.surface(brightness).withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.3],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator migliorato
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Passo ${provider.currentStep + 1} di ${CreateAppWizardProvider.totalSteps}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Pulsanti di navigazione
              Row(
                children: [
                  // Back button migliorato
                  if (provider.canGoBack)
                    Expanded(
                      child: _buildNavigationButton(
                        text: 'Indietro',
                        icon: Icons.arrow_back_ios_rounded,
                        isSecondary: true,
                        onTap: () => _handleBack(provider),
                        enabled: !provider.isGenerating,
                      ),
                    ),
                  
                  if (provider.canGoBack) const SizedBox(width: 20),
                  
                  // Next/Create button migliorato
                  Expanded(
                    flex: provider.canGoBack ? 2 : 3,
                    child: _buildNavigationButton(
                      text: provider.isLastStep ? '🚀 Crea App' : 'Avanti',
                      icon: provider.isLastStep 
                          ? Icons.rocket_launch_rounded 
                          : Icons.arrow_forward_ios_rounded,
                      isSecondary: false,
                      onTap: () => _handleNext(provider),
                      enabled: provider.isCurrentStepValid && !provider.isGenerating,
                      isLoading: provider.isGenerating,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String text,
    required IconData icon,
    required bool isSecondary,
    required VoidCallback onTap,
    required bool enabled,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: isPrimary 
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          highlightColor: isPrimary 
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              vertical: 18, 
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              gradient: enabled && !isSecondary
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.9),
                        AppColors.primaryTint,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSecondary
                  ? AppColors.surface(brightness).withValues(alpha: 0.8)
                  : enabled
                      ? null
                      : AppColors.surface(brightness).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSecondary
                    ? AppColors.border(brightness).withValues(alpha: 0.4)
                    : enabled && !isSecondary
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: enabled && !isSecondary
                  ? [
                      // Ombra principale
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      // Ombra secondaria più leggera
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                    ]
                  : isSecondary
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSecondary 
                            ? AppColors.primary 
                            : Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: isSecondary
                        ? AppColors.primary
                        : enabled
                            ? Colors.white
                            : AppColors.textTertiary,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSecondary
                          ? AppColors.primary
                          : enabled
                              ? Colors.white
                              : AppColors.textTertiary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
      provider.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
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