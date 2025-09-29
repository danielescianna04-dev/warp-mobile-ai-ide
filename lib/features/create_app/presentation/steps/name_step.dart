import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../providers/create_app_wizard_provider.dart';

class NameStep extends StatefulWidget {
  const NameStep({super.key});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> with AutomaticKeepAliveStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _packageController;
  late TextEditingController _descriptionController;
  late FocusNode _nameFocus;
  late FocusNode _packageFocus;
  late FocusNode _descriptionFocus;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _packageController = TextEditingController();
    _descriptionController = TextEditingController();
    _nameFocus = FocusNode();
    _packageFocus = FocusNode();
    _descriptionFocus = FocusNode();
    
    // Auto focus on name field when step is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _packageFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<CreateAppWizardProvider>(
      builder: (context, provider, child) {
        // Initialize controllers with current data
        if (_nameController.text != provider.wizardData.appName) {
          _nameController.text = provider.wizardData.appName;
        }
        if (_packageController.text != provider.wizardData.packageName) {
          _packageController.text = provider.wizardData.packageName;
        }
        if (_descriptionController.text != provider.wizardData.description) {
          _descriptionController.text = provider.wizardData.description;
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // App name field
              _buildAppNameField(provider),
              
              const SizedBox(height: 24),
              
              // Package name field
              _buildPackageNameField(provider),
              
              const SizedBox(height: 24),
              
              // Description field
              _buildDescriptionField(provider),
              
              const SizedBox(height: 32),
              
              // Tips section
              _buildTipsSection(),
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
              Icons.edit_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Iniziamo con il nome',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli un nome memorabile per la tua applicazione',
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

  Widget _buildAppNameField(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    final error = provider.validateAppName(_nameController.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome App *',
          style: TextStyle(
            color: AppColors.titleText(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.5)
                  : _nameFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border(brightness).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'es. MiaApp, TaskManager, PhotoEditor',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.apps_rounded,
                  color: _nameFocus.hasFocus 
                      ? AppColors.primary 
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              provider.updateAppName(value);
            },
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              _packageFocus.requestFocus();
            },
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPackageNameField(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    final error = provider.validatePackageName(_packageController.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Package Name *',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Identificativo univoco dell\'app (es. com.company.appname)',
              child: Icon(
                Icons.help_outline,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.5)
                  : _packageFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border(brightness).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _packageController,
            focusNode: _packageFocus,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'SF Mono',
            ),
            decoration: InputDecoration(
              hintText: provider.wizardData.autoGeneratedPackageName.isNotEmpty
                  ? provider.wizardData.autoGeneratedPackageName
                  : 'com.company.appname',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
                fontFamily: 'SF Mono',
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.code_rounded,
                  color: _packageFocus.hasFocus 
                      ? AppColors.primary 
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              provider.updatePackageName(value);
            },
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              _descriptionFocus.requestFocus();
            },
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_packageController.text.isEmpty && provider.wizardData.autoGeneratedPackageName.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _packageController.text = provider.wizardData.autoGeneratedPackageName;
              provider.updatePackageName(provider.wizardData.autoGeneratedPackageName);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Usa suggerimento: ${provider.wizardData.autoGeneratedPackageName}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField(CreateAppWizardProvider provider) {
    final brightness = Theme.of(context).brightness;
    final error = provider.validateDescription(_descriptionController.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrizione *',
          style: TextStyle(
            color: AppColors.titleText(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.5)
                  : _descriptionFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border(brightness).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            maxLines: 3,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Descrivi brevemente cosa fa la tua app e a chi è rivolta...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.description_rounded,
                  color: _descriptionFocus.hasFocus 
                      ? AppColors.primary 
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              provider.updateDescription(value);
            },
            textInputAction: TextInputAction.done,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${_descriptionController.text.length}/200 caratteri',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final brightness = Theme.of(context).brightness;
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
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Suggerimenti',
                style: TextStyle(
                  color: AppColors.titleText(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            '• Usa un nome breve e memorabile',
            '• Evita caratteri speciali nel nome',
            '• Il package name deve seguire il formato reverse domain',
            '• Descrivi chiaramente lo scopo dell\'app',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tip,
              style: TextStyle(
                color: AppColors.bodyText(brightness).withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }
}