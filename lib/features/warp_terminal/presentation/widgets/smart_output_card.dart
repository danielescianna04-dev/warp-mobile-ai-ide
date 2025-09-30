import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/app_colors.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: output.gradientColors.map((c) => 
            c.withValues(alpha: brightness == Brightness.dark ? c.a * 0.3 : c.a * 0.2)
          ).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: output.gradientColors.first.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: output.gradientColors.first.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icona e titolo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: output.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Icona
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      output.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Titolo e sottotitolo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          output.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (output.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            output.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Body con dettagli e URL
            if (output.detail != null || output.url != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness).withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dettagli
                    if (output.detail != null) ...[
                      Text(
                        output.detail!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'SF Mono',
                        ),
                      ),
                      if (output.url != null)
                        const SizedBox(height: 12),
                    ],
                    
                    // URL button
                    if (output.url != null)
                      _buildUrlButton(context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUrlButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Copia URL negli appunti
        Clipboard.setData(ClipboardData(text: output.url!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('URL copiato negli appunti'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (onUrlTap != null) {
          onUrlTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              output.gradientColors.first.withValues(alpha: 0.15),
              output.gradientColors.last.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: output.gradientColors.first.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language_rounded,
              color: output.gradientColors.first,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                output.url!,
                style: TextStyle(
                  color: output.gradientColors.first,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Mono',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: output.gradientColors.first.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.content_copy_rounded,
                color: output.gradientColors.first,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
