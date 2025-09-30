import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../providers/ai_app_generator_provider.dart';

class AIAppGeneratorPage extends StatefulWidget {
  const AIAppGeneratorPage({super.key});

  @override
  State<AIAppGeneratorPage> createState() => _AIAppGeneratorPageState();
}

class _AIAppGeneratorPageState extends State<AIAppGeneratorPage>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _suggestions = [
    'App per prendere note',
    'Chat con AI',
    'App fitness',
    'App meteo',
    'Lista spesa',
    'Lettore musicale',
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Auto focus dopo un breve delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _promptFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _promptController.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return ChangeNotifierProvider(
      create: (_) => AIAppGeneratorProvider(),
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Consumer<AIAppGeneratorProvider>(
                  builder: (context, provider, child) => Column(
                    children: [
                      // Header
                      _buildHeader(),
                      
                      // Content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              
                              // Main prompt area with integrated tools
                              _buildPromptArea(provider),
                              
                              const SizedBox(height: 32),
                              
                              // Suggestions
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildSuggestions(),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border(brightness).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.titleText(brightness),
                  size: 20,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // AI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryTint,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Powered',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptArea(AIAppGeneratorProvider provider) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Descrivi la tua\nidea app',
                style: TextStyle(
                  color: AppColors.titleText(brightness),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: '...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Dimmi cosa vuoi creare e lo realizzerò per te',
          style: TextStyle(
            color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
            fontSize: 16,
            height: 1.4,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Input field with integrated tools
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface(brightness).withValues(alpha: 0.6),
                AppColors.surface(brightness).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _promptFocus.hasFocus
                  ? AppColors.primary.withValues(alpha: 0.8)
                  : AppColors.border(brightness).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: _promptFocus.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _promptController,
                focusNode: _promptFocus,
                maxLines: null,
                minLines: 4,
                style: TextStyle(
                  color: AppColors.titleText(brightness),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'es. Un\'app social per proprietari di animali dove possono condividere foto, trovare veterinari vicini e connettersi con altri proprietari...',
                  hintStyle: TextStyle(
                    color: AppColors.bodyText(brightness).withValues(alpha: 0.6),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                ),
                onChanged: (value) {
                  provider.updatePrompt(value);
                },
              ),
              
              // Integrated tools row
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Attachment button
                    _buildCompactToolButton(
                      icon: Icons.attach_file_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Implementa allegato file/immagini
                      },
                      brightness: brightness,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Voice input button
                    _buildCompactToolButton(
                      icon: Icons.mic_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Implementa input vocale
                      },
                      brightness: brightness,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Generate button - flexible per evitare overflow
                    Flexible(
                      child: _buildGenerateButton(provider, brightness),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Idee popolari',
          style: TextStyle(
            color: AppColors.titleText(brightness).withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _suggestions.map((suggestion) {
            return _buildSuggestionChip(suggestion, brightness);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion, Brightness brightness) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _promptController.text = suggestion;
          final provider = Provider.of<AIAppGeneratorProvider>(context, listen: false);
          provider.updatePrompt(suggestion);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              color: AppColors.bodyText(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToolButton({
    required IconData icon,
    required VoidCallback onTap,
    required Brightness brightness,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surface(brightness).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border(brightness).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : AppColors.bodyText(brightness).withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(AIAppGeneratorProvider provider, Brightness brightness) {
    final canGenerate = provider.prompt.trim().isNotEmpty && !provider.isGenerating;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canGenerate ? () => _handleGenerate(provider) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            constraints: const BoxConstraints(
              minWidth: 100,
              maxWidth: 140,
            ),
            decoration: BoxDecoration(
              gradient: canGenerate
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryTint,
                      ],
                    )
                  : null,
              color: canGenerate
                  ? null
                  : AppColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: canGenerate
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isGenerating)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: canGenerate
                        ? Colors.white
                        : AppColors.bodyText(brightness).withValues(alpha: 0.5),
                    size: 16,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    provider.isGenerating ? 'Creazione...' : 'Crea',
                    style: TextStyle(
                      color: canGenerate
                          ? Colors.white
                          : AppColors.bodyText(brightness).withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _handleGenerate(AIAppGeneratorProvider provider) async {
    HapticFeedback.mediumImpact();
    
    try {
      final result = await provider.generateApp();
      
      if (mounted && result != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App "${result.appName}" creata con successo!',
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
        
        // Navigate back to terminal or project view
        Navigator.of(context).pop(result);
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
                    'Errore nella creazione dell\'app: ${error.toString()}',
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
}