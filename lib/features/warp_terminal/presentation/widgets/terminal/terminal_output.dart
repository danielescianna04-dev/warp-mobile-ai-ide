import 'package:flutter/material.dart';
import '../../../../../shared/constants/app_colors.dart';
import '../../../data/models/terminal_item.dart';

class TerminalOutput extends StatelessWidget {
  final List<TerminalItem> items;

  const TerminalOutput({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        Color textColor;
        String prefix = '';
        
        switch (item.type) {
          case TerminalItemType.command:
            textColor = AppColors.purpleMedium;
            prefix = '\$ ';
            break;
          case TerminalItemType.output:
            textColor = AppColors.textPrimary;
            prefix = '';
            break;
          case TerminalItemType.error:
            textColor = AppColors.error;
            prefix = '✗ ';
            break;
          case TerminalItemType.system:
          default:
            textColor = AppColors.textTertiary;
            prefix = '✓ ';
            break;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SelectableText.rich(
            TextSpan(
              children: [
                if (prefix.isNotEmpty)
                  TextSpan(
                    text: prefix,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'SourceCodePro',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                TextSpan(
                  text: item.content,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'SourceCodePro',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}