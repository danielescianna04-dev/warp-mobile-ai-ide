import 'package:flutter/material.dart';

/// Card minimal per mostrare comandi inviati
class CommandCard extends StatelessWidget {
  final String command;
  final DateTime timestamp;
  
  const CommandCard({
    super.key,
    required this.command,
    required this.timestamp,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'ora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m fa';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h fa';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    // Rimuovi il prompt se presente (es: "~/dir $ comando" -> "comando")
    String cleanCommand = command;
    if (command.contains('\$')) {
      final parts = command.split('\$');
      if (parts.length > 1) {
        cleanCommand = parts[1].trim();
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? const Color(0xFF0D0D0D)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona prompt
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: brightness == Brightness.dark
                  ? const Color(0xFF06B6D4)
                  : const Color(0xFF0891B2),
            ),
          ),
          const SizedBox(width: 8),
          // Comando
          Expanded(
            child: Text(
              cleanCommand,
              style: TextStyle(
                color: brightness == Brightness.dark
                    ? const Color(0xFFE5E5E5)
                    : const Color(0xFF1A1A1A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF Mono',
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timestamp
          Text(
            _formatTime(timestamp),
            style: TextStyle(
              color: brightness == Brightness.dark
                  ? const Color(0xFF666666)
                  : const Color(0xFF999999),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
