import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/wizard/create_app_models.dart';
import '../../providers/create_app_wizard_provider.dart';

class AppTypeStep extends StatefulWidget {
  const AppTypeStep({super.key});

  @override
  State<AppTypeStep> createState() => _AppTypeStepState();
}

class _AppTypeStepState extends State<AppTypeStep> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CreateAppWizardProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // App type cards
              Column(
                children: AppType.values.map((appType) {
                  final isSelected = provider.wizardData.appType == appType;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAppTypeCard(
                      context,
                      appType,
                      isSelected,
                      () => _selectAppType(provider, appType),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Info section
              _buildInfoSection(provider.wizardData.appType),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient(brightness),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.devices_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Su quale piattaforma?',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli dove la tua app verrà utilizzata',
            style: TextStyle(
              color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppTypeCard(
    BuildContext context,
    AppType appType,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final brightness = Theme.of(context).brightness;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border(brightness).withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.heroGradient(brightness)
                        : LinearGradient(
                            colors: [
                              AppColors.surface(brightness).withValues(alpha: 0.8),
                              AppColors.surface(brightness).withValues(alpha: 0.4),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.border(brightness).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      appType.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appType.title,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.titleText(brightness),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appType.description,
                        style: TextStyle(
                          color: AppColors.bodyText(brightness).withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border(brightness).withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(AppType selectedType) {
    final brightness = Theme.of(context).brightness;
    
    // Get sample frameworks for the selected type
    final compatibleFrameworks = Framework.getCompatibleFrameworks(selectedType);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informazioni: ${selectedType.title}',
                style: TextStyle(
                  color: AppColors.titleText(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Available frameworks
          Text(
            'Framework compatibili:',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: compatibleFrameworks.map((framework) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      framework.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      framework.name,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Platform specific info
          _buildPlatformSpecificInfo(selectedType),
        ],
      ),
    );
  }

  Widget _buildPlatformSpecificInfo(AppType appType) {
    final brightness = Theme.of(context).brightness;
    
    List<String> features = [];
    String title = '';
    
    switch (appType) {
      case AppType.mobile:
        title = 'Caratteristiche Mobile:';
        features = [
          '• Accesso a fotocamera e sensori',
          '• Notifiche push native',
          '• Store distribution (App Store, Play Store)',
          '• Performance ottimizzate per dispositivi mobili',
          '• Integrazione con servizi di sistema',
        ];
        break;
      case AppType.desktop:
        title = 'Caratteristiche Desktop:';
        features = [
          '• Accesso completo al filesystem',
          '• Finestre ridimensionabili e multi-monitor',
          '• Integrazione con menu di sistema',
          '• Scorciatoie da tastiera avanzate',
          '• Esecuzione in background',
        ];
        break;
      case AppType.web:
        title = 'Caratteristiche Web:';
        features = [
          '• Accesso universale da browser',
          '• Aggiornamenti istantanei',
          '• Responsive design automatico',
          '• Condivisione semplice tramite URL',
          '• SEO e indicizzazione sui motori di ricerca',
        ];
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.titleText(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            feature,
            style: TextStyle(
              color: AppColors.bodyText(brightness).withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        )),
      ],
    );
  }

  void _selectAppType(CreateAppWizardProvider provider, AppType appType) {
    HapticFeedback.lightImpact();
    provider.updateAppType(appType);
  }
}