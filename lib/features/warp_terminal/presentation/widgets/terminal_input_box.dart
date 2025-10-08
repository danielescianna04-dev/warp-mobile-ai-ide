import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/terminal/syntax_text_field.dart';

class TerminalInputBox extends StatelessWidget {
  final dynamic controller; // Può essere TextEditingController o SyntaxHighlightingController
  final FocusNode focusNode;
  final String hintText;
  final bool showModelSelector;
  final bool showModeToggle;
  final bool isTerminalMode;
  final bool useSyntaxHighlighting;
  final VoidCallback? onSend;
  final ValueChanged<String>? onChanged;
  final Widget? modelSelector;
  final Widget? modeToggle;
  final Widget? toolsButton;
  final bool useTransparentStyle; // Per preview con glassmorphism
  final VoidCallback? onEditMode; // Callback per Edit button
  
  const TerminalInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Scrivi un comando...',
    this.showModelSelector = true,
    this.showModeToggle = true,
    this.isTerminalMode = true,
    this.useSyntaxHighlighting = true,
    this.onSend,
    this.onChanged,
    this.modelSelector,
    this.modeToggle,
    this.toolsButton,
    this.useTransparentStyle = false,
    this.onEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: useTransparentStyle
              ? LinearGradient(
                  colors: [
                    brightness == Brightness.dark
                        ? const Color(0xFF2a2a2a).withValues(alpha: 0.7)
                        : const Color(0xFFe0e0e0).withValues(alpha: 0.7),
                    brightness == Brightness.dark
                        ? const Color(0xFF1a1a1a).withValues(alpha: 0.7)
                        : const Color(0xFFd0d0d0).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    AppColors.surface(brightness).withValues(alpha: 0.98),
                    AppColors.surface(brightness).withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: useTransparentStyle
                ? (brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2))
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: useTransparentStyle ? 0.3 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            if (!useTransparentStyle)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 50,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top controls
            if (showModeToggle || showModelSelector)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    if (modeToggle != null)
                      modeToggle!
                    else if (showModeToggle)
                      _buildDefaultModeToggle(brightness),
                    const Spacer(),
                    if (modelSelector != null)
                      modelSelector!
                    else if (showModelSelector)
                      _buildDefaultModelSelector(brightness),
                  ],
                ),
              ),
            // Input row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tools button
                  if (toolsButton != null)
                    toolsButton!
                  else
                    _buildDefaultToolsButton(brightness),
                  const SizedBox(width: 12),
                  // Input field con background
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: useTransparentStyle
                            ? (brightness == Brightness.dark
                                ? const Color(0xFF1a1a1a).withValues(alpha: 0.5)
                                : const Color(0xFFd0d0d0).withValues(alpha: 0.5))
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: useSyntaxHighlighting
                        ? SyntaxTextField(
                            controller: controller,
                            focusNode: focusNode,
                            maxLines: null,
                            constraints: const BoxConstraints(maxHeight: 120),
                            style: TextStyle(
                              color: AppColors.titleText(brightness),
                              fontSize: 14,
                              fontFamily: 'SF Mono',
                              height: 1.4,
                            ),
                            hintText: hintText,
                            hintStyle: TextStyle(
                              color: AppColors.bodyText(brightness).withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              isDense: false,
                            ),
                            onChanged: onChanged,
                            onSubmitted: (_) => onSend?.call(),
                          )
                        : TextField(
                            controller: controller as TextEditingController,
                            focusNode: focusNode,
                            maxLines: null,
                            style: TextStyle(
                              color: AppColors.titleText(brightness),
                              fontSize: 14,
                              fontFamily: 'SF Mono',
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: TextStyle(
                                color: AppColors.bodyText(brightness).withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              isDense: false,
                            ),
                            onChanged: onChanged,
                            onSubmitted: (_) => onSend?.call(),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  _buildSendButton(brightness),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultModeToggle(Brightness brightness) {
    return InkWell(
      onTap: onEditMode,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              size: 16,
              color: AppColors.bodyText(brightness),
            ),
            const SizedBox(width: 6),
            Text(
              'Edit',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultModelSelector(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Auto',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.bodyText(brightness),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultToolsButton(Brightness brightness) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.add,
        color: AppColors.bodyText(brightness),
        size: 20,
      ),
    );
  }
  
  Widget _buildSendButton(Brightness brightness) {
    return GestureDetector(
      onTap: onSend,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_upward_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
