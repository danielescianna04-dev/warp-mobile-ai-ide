import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/smart_output_parser.dart';

/// Card intelligente per mostrare output parsato stile Warp
class SmartOutputCard extends StatelessWidget {
  final SmartOutput output;
  final VoidCallback? onUrlTap;
  
  const SmartOutputCard({
    super.key,
    required this.output,
    this.onUrlTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: output.gradientColors.first.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header minimal: icona piccola + titolo in linea
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona piccola
              Icon(
                output.icon,
                color: output.gradientColors.first.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 10),
              // Titolo e sottotitolo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      output.title.replaceAll(RegExp(r'[🚀⚙️🌐🖥️✅❌⚠️⏳]'), '').trim(),
                      style: TextStyle(
                        color: brightness == Brightness.dark
                            ? const Color(0xFFE5E5E5)
                            : const Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (output.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        output.subtitle!,
                        style: TextStyle(
                          color: brightness == Brightness.dark
                              ? const Color(0xFF8C8C8C)
                              : const Color(0xFF666666),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // URL button minimal (se presente)
          if (output.url != null) ...[
            const SizedBox(height: 10),
            _buildUrlButton(context, brightness),
          ],
        ],
      ),
    );
  }
  
  Widget _buildUrlButton(BuildContext context, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        // Copia URL negli appunti
        Clipboard.setData(ClipboardData(text: output.url!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('URL copiato'),
            backgroundColor: brightness == Brightness.dark
                ? const Color(0xFF2D2D2D)
                : const Color(0xFF404040),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
        
        if (onUrlTap != null) {
          onUrlTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brightness == Brightness.dark
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                output.url!,
                style: TextStyle(
                  color: output.gradientColors.first.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'SF Mono',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy_rounded,
              color: brightness == Brightness.dark
                  ? const Color(0xFF8C8C8C)
                  : const Color(0xFF666666),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
