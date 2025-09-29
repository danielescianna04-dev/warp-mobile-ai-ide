import 'package:flutter/material.dart';
import 'presentation/pages/simple_terminal_page.dart';
import 'data/models/chat_session.dart';

// Pagina di test per provare il terminale con dati di esempio
class TestTerminalPage extends StatelessWidget {
  const TestTerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Warp Terminal'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SimpleTerminalPage(),
                  ),
                );
              },
              icon: const Icon(Icons.terminal),
              label: const Text('Apri Terminal'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _testChatWithGitHub(context);
              },
              icon: const Icon(Icons.account_tree),
              label: const Text('Test Chat GitHub'),
            ),
            const SizedBox(height: 20),
            Text(
              'Comandi di test disponibili nel terminal:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ls - Lista file e directory'),
                Text('• pwd - Directory corrente'),
                Text('• git status - Stato repository'),
                Text('• flutter --version - Versione Flutter'),
                Text('• flutter pub get - Dipendenze'),
                Text('• clear - Pulisci terminal'),
                Text('• help - Mostra aiuto'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testChatWithGitHub(BuildContext context) {
    // Esempio di chat associata a una repository GitHub
    final testChatSession = ChatSession(
      id: 'test-github-chat-001',
      title: 'Setup Flutter App con Firebase',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastUsed: DateTime.now().subtract(const Duration(minutes: 15)),
      messages: [],
      aiModel: 'gpt-4',
      repositoryId: 'repo-12345',
      repositoryName: 'warp-mobile-ai-ide',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat con Repository GitHub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titolo: ${testChatSession.title}'),
            const SizedBox(height: 8),
            Text('Repository: ${testChatSession.repositoryName}'),
            const SizedBox(height: 8),
            Text('Modello AI: ${testChatSession.aiModel}'),
            const SizedBox(height: 8),
            Text('Creata: ${_formatDateTime(testChatSession.createdAt)}'),
            const SizedBox(height: 16),
            const Text(
              'Questa chat sarebbe mostrata nella sidebar con l\'icona GitHub e il nome della repository.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}