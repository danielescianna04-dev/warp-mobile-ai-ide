import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/constants/app_colors.dart';
import '../providers/terminal_provider.dart';
import '../widgets/terminal/terminal_input.dart';
import '../widgets/terminal/terminal_output.dart';
import '../widgets/terminal/welcome_view.dart';

class SimpleTerminalPage extends StatelessWidget {
  const SimpleTerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TerminalProvider(),
      child: const _SimpleTerminalView(),
    );
  }
}

class _SimpleTerminalView extends StatefulWidget {
  const _SimpleTerminalView();

  @override
  State<_SimpleTerminalView> createState() => _SimpleTerminalViewState();
}

class _SimpleTerminalViewState extends State<_SimpleTerminalView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.terminal,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Terminal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<TerminalProvider>(
            builder: (context, provider, _) {
              if (!provider.hasOutput) return const SizedBox.shrink();
              
              return IconButton(
                icon: Icon(Icons.clear_all, color: AppColors.textSecondary),
                onPressed: () {
                  provider.clearTerminal();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<TerminalProvider>(
        builder: (context, provider, _) {
          // Scorri verso il basso quando vengono aggiunti nuovi elementi
          if (provider.hasOutput) {
            _scrollToBottom();
          }

          return Column(
            children: [
              Expanded(
                child: provider.hasOutput
                    ? SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TerminalOutput(items: provider.items),
                            if (provider.isLoading)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.purpleMedium,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Elaborazione...',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 12,
                                        fontFamily: 'SourceCodePro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    : const WelcomeView(),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border(brightness),
                      width: 1,
                    ),
                  ),
                ),
                child: TerminalInput(
                  controller: _inputController,
                  onSubmitted: (command) {
                    provider.executeCommand(command);
                    _inputController.clear();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}