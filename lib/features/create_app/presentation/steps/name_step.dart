import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../providers/create_app_wizard_provider.dart';

class NameStep extends StatefulWidget {
  const NameStep({super.key});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late TextEditingController _nameController;
  late TextEditingController _packageController;
  late TextEditingController _descriptionController;
  late FocusNode _nameFocus;
  late FocusNode _packageFocus;
  late FocusNode _descriptionFocus;


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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with icon
              _buildHeader(),
              
              const SizedBox(height: 48),
              
              // Form fields container
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App name field
                    _buildAppNameField(provider),
                    
                    const SizedBox(height: 28),
                    
                    // Package name field
                    _buildPackageNameField(provider),
                    
                    const SizedBox(height: 28),
                    
                    // Description field
                    _buildDescriptionField(provider),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
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
          // Icona migliorata con gradiente e ombre più sofisticate
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primaryTint,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                // Ombra principale più profonda
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
                // Seconda ombra più leggera e diffusa
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 25),
                  spreadRadius: 5,
                ),
                // Ombra interna per effetto 3D
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          
          // Titolo principale più impattante
          Text(
            'Diamo vita alla tua idea',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Sottotitolo più chiaro e invitante
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Scegli un nome unico e memorabile\nper la tua nuova applicazione',
              style: TextStyle(
                color: AppColors.bodyText(brightness).withValues(alpha: 0.85),
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Elemento decorativo
          const SizedBox(height: 24),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
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
            color: AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.6)
                  : _nameFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : AppColors.border(brightness).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: _nameFocus.hasFocus ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : [],
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
            color: AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.6)
                  : _packageFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : AppColors.border(brightness).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: _packageFocus.hasFocus ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : [],
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
            color: AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.6)
                  : _descriptionFocus.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : AppColors.border(brightness).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: _descriptionFocus.hasFocus ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : [],
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
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface(brightness).withValues(alpha: 0.4),
            AppColors.surface(brightness).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icona più bella
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consigli utili',
                      style: TextStyle(
                        color: AppColors.titleText(brightness),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Per creare un\'app di successo',
                      style: TextStyle(
                        color: AppColors.bodyText(brightness).withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Lista suggerimenti migliorata
          ...[
            {
              'icon': Icons.short_text_rounded,
              'text': 'Usa un nome breve e memorabile'
            },
            {
              'icon': Icons.block_rounded,
              'text': 'Evita caratteri speciali nel nome'
            },
            {
              'icon': Icons.dns_rounded,
              'text': 'Il package segue il formato reverse domain'
            },
            {
              'icon': Icons.description_rounded,
              'text': 'Descrivi chiaramente lo scopo dell\'app'
            },
          ].asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;
            return Container(
              margin: EdgeInsets.only(
                bottom: index < 3 ? 16 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      tip['text'] as String,
                      style: TextStyle(
                        color: AppColors.bodyText(brightness).withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}