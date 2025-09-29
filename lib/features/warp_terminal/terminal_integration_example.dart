import 'package:flutter/material.dart';
import 'presentation/pages/simple_terminal_page.dart';
import 'test_terminal_page.dart';

/// Esempio di integrazione del terminale Warp nell'app principale
/// 
/// Questo file mostra come integrare il terminale nell'app esistente
/// e può essere usato come riferimento per l'implementazione finale.

class TerminalIntegrationExample {
  /// Navigazione al terminale semplice
  static void openSimpleTerminal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SimpleTerminalPage(),
      ),
    );
  }
  
  /// Navigazione alla pagina di test con esempi
  static void openTestPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TestTerminalPage(),
      ),
    );
  }
  
  /// Widget per aggiungere un pulsante di accesso rapido al terminale
  static Widget terminalFloatingButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => openSimpleTerminal(context),
      backgroundColor: const Color(0xFF6366F1), // AppColors.purpleMedium
      child: const Icon(
        Icons.terminal,
        color: Colors.white,
      ),
    );
  }
  
  /// Widget per menu item nelle drawer/sidebar
  static Widget terminalMenuItem(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // AppColors.purpleGradient
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.terminal,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text(
        'Terminal',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text('Accesso al terminale integrato'),
      onTap: () => openSimpleTerminal(context),
    );
  }
  
  /// Widget per card di accesso rapido
  static Widget terminalCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openSimpleTerminal(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.terminal,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Terminal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Accesso completo al terminale',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esempio di utilizzo in una pagina dell'app
class ExampleUsagePage extends StatelessWidget {
  const ExampleUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Integration Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modalità di Accesso al Terminal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Card per terminale semplice
            TerminalIntegrationExample.terminalCard(context),
            
            const SizedBox(height: 20),
            
            // Lista delle opzioni
            TerminalIntegrationExample.terminalMenuItem(context),
            
            const SizedBox(height: 20),
            
            // Pulsanti diretti
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => TerminalIntegrationExample.openSimpleTerminal(context),
                    icon: const Icon(Icons.terminal),
                    label: const Text('Terminal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => TerminalIntegrationExample.openTestPage(context),
                    icon: const Icon(Icons.science),
                    label: const Text('Test'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Funzionalità Disponibili:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildFeatureItem(
              icon: Icons.code,
              title: 'Comandi Simulati',
              description: 'ls, pwd, git, flutter, clear, help e altri',
            ),
            _buildFeatureItem(
              icon: Icons.palette,
              title: 'Syntax Highlighting',
              description: 'Colori differenziati per comandi, output ed errori',
            ),
            _buildFeatureItem(
              icon: Icons.account_tree,
              title: 'GitHub Integration',
              description: 'Supporto per chat associate a repository',
            ),
            _buildFeatureItem(
              icon: Icons.architecture,
              title: 'Architettura Modulare',
              description: 'Provider pattern con widget riutilizzabili',
            ),
          ],
        ),
      ),
      floatingActionButton: TerminalIntegrationExample.terminalFloatingButton(context),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}