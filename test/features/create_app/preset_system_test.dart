import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:warp_mobile_ai_ide/core/wizard/preset_apps.dart';
import 'package:warp_mobile_ai_ide/features/create_app/providers/create_app_wizard_provider.dart';
import 'package:warp_mobile_ai_ide/features/create_app/presentation/widgets/preset_card.dart';
import 'package:warp_mobile_ai_ide/features/create_app/presentation/steps/preset_selection_step.dart';

void main() {
  group('Preset System Tests', () {
    testWidgets('PresetAppsRepository should return correct presets', (tester) async {
      final presetApps = PresetAppsRepository.getPresetApps();
      final customPreset = PresetAppsRepository.getCustomPreset();
      
      // Verifica che ci siano 8 preset app (escluso custom)
      expect(presetApps.length, 8);
      
      // Verifica che custom preset esista
      expect(customPreset.type, PresetAppType.custom);
      
      // Verifica che tutti i preset abbiano configurazioni valide
      for (final preset in presetApps) {
        expect(preset.name, isNotEmpty);
        expect(preset.description, isNotEmpty);
        expect(preset.framework, isNotEmpty);
        expect(preset.appType, isNotEmpty);
      }
    });

    testWidgets('PresetCard should display correct information', (tester) async {
      final config = PresetAppsRepository.getConfig(PresetAppType.noteTaking)!;
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetCard(
              config: config,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verifica che il nome sia visualizzato
      expect(find.text(config.name), findsOneWidget);
      
      // Verifica che l'icona sia visualizzata
      expect(find.byIcon(config.icon), findsOneWidget);
      
      // Verifica che il framework badge sia visualizzato
      expect(find.text(config.framework.toUpperCase()), findsOneWidget);
      
      // Testa l'interazione tap
      await tester.tap(find.byType(PresetCard));
      expect(tapped, isTrue);
    });

    testWidgets('PresetCard should show selection state', (tester) async {
      final config = PresetAppsRepository.getConfig(PresetAppType.aiChat)!;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetCard(
              config: config,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verifica che il checkmark sia visualizzato quando selezionato
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('CreateAppWizardProvider should handle preset selection correctly', (tester) async {
      late CreateAppWizardProvider provider;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => CreateAppWizardProvider(),
            child: Consumer<CreateAppWizardProvider>(
              builder: (context, p, child) {
                provider = p;
                return Container();
              },
            ),
          ),
        ),
      );

      // Test selezione preset Note Taking
      provider.selectPreset(PresetAppType.noteTaking);
      await tester.pump();
      
      expect(provider.wizardData.selectedPreset, 'noteTaking');
      expect(provider.wizardData.isPresetSelected, isTrue);
      expect(provider.wizardData.isCustomFlow, isFalse);
      expect(provider.wizardData.framework?.name, 'Flutter');
      expect(provider.wizardData.features.isNotEmpty, isTrue);

      // Test selezione custom
      provider.selectPreset(PresetAppType.custom);
      await tester.pump();
      
      expect(provider.wizardData.selectedPreset, 'custom');
      expect(provider.wizardData.isPresetSelected, isFalse);
      expect(provider.wizardData.isCustomFlow, isTrue);
    });

    testWidgets('PresetSelectionStep should render grid of preset cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (context) => CreateAppWizardProvider(),
              child: const PresetSelectionStep(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Attendi che le animazioni si completino

      // Verifica che il titolo sia visualizzato
      expect(find.text('Describe your app idea...'), findsOneWidget);
      
      // Verifica che tutte le 9 card siano presenti (8 preset + 1 custom)
      expect(find.byType(PresetCard), findsNWidgets(9));
      
      // Verifica che alcune card specifiche siano presenti
      expect(find.text('Note taking app'), findsOneWidget);
      expect(find.text('AI chat app'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    test('PresetAppsRepository.getConfig should return correct config', () {
      final noteConfig = PresetAppsRepository.getConfig(PresetAppType.noteTaking);
      final aiChatConfig = PresetAppsRepository.getConfig(PresetAppType.aiChat);
      
      expect(noteConfig?.name, 'Note taking app');
      expect(noteConfig?.framework, 'flutter');
      expect(noteConfig?.features.contains('markdown'), isTrue);
      
      expect(aiChatConfig?.name, 'AI chat app');
      expect(aiChatConfig?.features.contains('ai_integration'), isTrue);
    });

    test('PresetAppsRepository.isCustom should work correctly', () {
      expect(PresetAppsRepository.isCustom(PresetAppType.custom), isTrue);
      expect(PresetAppsRepository.isCustom(PresetAppType.noteTaking), isFalse);
      expect(PresetAppsRepository.isCustom(null), isTrue);
    });

    group('Data Model Tests', () {
      test('CreateAppWizardData should handle preset properties correctly', () {
        const wizardData = CreateAppWizardData(
          appName: 'TestApp',
          selectedPreset: 'noteTaking',
        );
        
        expect(wizardData.isPresetSelected, isTrue);
        expect(wizardData.isCustomFlow, isFalse);
        
        const customData = CreateAppWizardData(
          appName: 'TestApp',
          selectedPreset: 'custom',
        );
        
        expect(customData.isPresetSelected, isFalse);
        expect(customData.isCustomFlow, isTrue);
        
        const noPresetData = CreateAppWizardData(
          appName: 'TestApp',
        );
        
        expect(noPresetData.isPresetSelected, isFalse);
        expect(noPresetData.isCustomFlow, isTrue);
      });

      test('CreateAppWizardData copyWith should preserve preset selection', () {
        const original = CreateAppWizardData(
          appName: 'Original',
          selectedPreset: 'aiChat',
        );
        
        final copy = original.copyWith(appName: 'Modified');
        
        expect(copy.appName, 'Modified');
        expect(copy.selectedPreset, 'aiChat');
        expect(copy.isPresetSelected, isTrue);
      });

      test('CreateAppWizardData toJson should include preset info', () {
        const wizardData = CreateAppWizardData(
          appName: 'TestApp',
          selectedPreset: 'weatherApp',
        );
        
        final json = wizardData.toJson();
        
        expect(json['selectedPreset'], 'weatherApp');
        expect(json.containsKey('selectedPreset'), isTrue);
      });
    });
  });
}