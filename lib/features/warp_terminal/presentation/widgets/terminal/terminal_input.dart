import 'package:flutter/material.dart';
import '../../../../../shared/constants/app_colors.dart';

class TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const TerminalInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Prompt symbol
          Text(
            '\$ ',
            style: TextStyle(
              color: AppColors.purpleMedium,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'SourceCodePro',
            ),
          ),
          // Input field
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'SourceCodePro',
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Inserisci un comando...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  fontFamily: 'SourceCodePro',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  onSubmitted(value);
                }
              },
              textInputAction: TextInputAction.done,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}