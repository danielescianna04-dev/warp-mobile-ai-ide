import 'package:flutter/material.dart';
import '../../../../../shared/constants/app_colors.dart';
import '../../data/models/chat_session.dart';

class ChatHistoryItem extends StatelessWidget {
  final ChatSession chat;
  final bool isSelected;
  final VoidCallback onTap;
  
  const ChatHistoryItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isGitHubChat = chat.repositoryId != null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.chatSelection(brightness)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icona GitHub a sinistra (sempre presente per mantenere allineamento)
            Container(
              width: 20, // Larghezza fissa per allineamento
              child: isGitHubChat 
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.account_tree_outlined,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    )
                  : const SizedBox.shrink(), // Spazio vuoto per chat normali
            ),
            const SizedBox(width: 8),
            
            // Contenuto chat (ora sempre allineato)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo chat
                  Text(
                    chat.title.length > 40 ? '${chat.title.substring(0, 40)}...' : chat.title,
                    style: TextStyle(
                      color: isSelected 
                          ? AppColors.titleText(brightness)
                          : AppColors.bodyText(brightness),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Nome repository se presente
                  if (isGitHubChat && chat.repositoryName != null) ...[ 
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: AppColors.textTertiary,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chat.repositoryName!,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}