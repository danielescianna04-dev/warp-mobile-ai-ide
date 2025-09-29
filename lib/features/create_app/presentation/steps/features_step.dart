import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/wizard/create_app_models.dart';
import '../providers/create_app_wizard_provider.dart';

class FeaturesStep extends StatelessWidget {
  const FeaturesStep({super.key});

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
              
              // Features grid
              _buildFeaturesGrid(provider),
              
              const SizedBox(height: 24),
              
              // Selected count
              _buildSelectedCount(provider),
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
              Icons.extension_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aggiungi funzionalità',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona le funzionalità di cui ha bisogno la tua app',
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

  Widget _buildFeaturesGrid(CreateAppWizardProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: AppFeature.values.length,
      itemBuilder: (context, index) {
        final feature = AppFeature.values[index];
        final isSelected = provider.wizardData.features.contains(feature);
        
        return _buildFeatureCard(
          feature,
          isSelected,
          () => _toggleFeature(provider, feature),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    AppFeature feature,
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
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
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  feature.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  feature.title,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.titleText(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  feature.description,
                  style: TextStyle(
                    color: AppColors.bodyText(brightness).withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCount(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    final selectedCount = provider.wizardData.features.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selectedCount > 0 ? Icons.check_circle : Icons.info_outline,
            color: selectedCount > 0 ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedCount > 0
                  ? '$selectedCount funzionalità selezionate'
                  : 'Seleziona almeno una funzionalità',
              style: TextStyle(
                color: selectedCount > 0 
                    ? AppColors.success 
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFeature(CreateAppWizardProvider provider, AppFeature feature) {
    HapticFeedback.lightImpact();
    provider.toggleFeature(feature);
  }
}