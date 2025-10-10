import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

class WorkstationLoadingPage extends StatelessWidget {
  final int progress;
  final int elapsed;
  final String repositoryName;
  
  const WorkstationLoadingPage({
    super.key,
    required this.progress,
    required this.elapsed,
    required this.repositoryName,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final barLength = 30;
    final filled = (progress / 100 * barLength).toInt();
    final empty = barLength - filled;
    
    // Spinner animation frames
    final frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    final spinner = frames[(elapsed ~/ 10) % frames.length];
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinner icon
              Text(
                spinner,
                style: TextStyle(
                  fontSize: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Avvio Workstation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Repository name
              Text(
                repositoryName,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Progress bar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border(brightness),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Progress percentage
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background(brightness),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '┌${'─' * (barLength + 2)}┐\n'
                        '│ ${'█' * filled}${'░' * empty} │\n'
                        '└${'─' * (barLength + 2)}┘',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${elapsed}s / ~180s',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Info text
              Text(
                'Primo avvio: 2-3 minuti\nSuccessivi: 20-30 secondi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
