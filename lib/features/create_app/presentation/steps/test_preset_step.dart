import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../providers/create_app_wizard_provider.dart';
import 'preset_selection_step.dart';

/// Test widget per visualizzare il PresetSelectionStep in isolazione
class TestPresetStepPage extends StatelessWidget {
  const TestPresetStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateAppWizardProvider(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Test Preset Selection'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Consumer<CreateAppWizardProvider>(
                  builder: (context, provider, child) {
                    return TextButton(
                      onPressed: () {
                        // Debug: stampa lo stato corrente
                        debugPrint('Wizard State:');
                        debugPrint('Selected Preset: ${provider.wizardData.selectedPreset}');
                        debugPrint('Is Preset Selected: ${provider.wizardData.isPresetSelected}');
                        debugPrint('Is Custom Flow: ${provider.wizardData.isCustomFlow}');
                        debugPrint('App Type: ${provider.wizardData.appType.name}');
                        debugPrint('Framework: ${provider.wizardData.framework?.name}');
                        debugPrint('Features: ${provider.wizardData.features.map((f) => f.name).toList()}');
                        
                        // Mostra uno snackbar con i dati
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Preset: ${provider.wizardData.selectedPreset ?? "None"}'),
                          ),
                        );
                      },
                      child: const Text('DEBUG'),
                    );
                  },
                ),
              ],
            ),
            backgroundColor: AppColors.background(Theme.of(context).brightness),
            extendBodyBehindAppBar: true,
            body: SafeArea(
              child: const PresetSelectionStep(),
            ),
          );
        },
      ),
    );
  }
}

/// Test utility per navigare al test page
class TestPresetRoute {
  static MaterialPageRoute<void> route() {
    return MaterialPageRoute(
      builder: (context) => const TestPresetStepPage(),
    );
  }
}