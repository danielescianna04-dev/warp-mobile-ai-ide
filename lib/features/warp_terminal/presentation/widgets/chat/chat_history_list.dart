import 'package:flutter/material.dart';
import '../../../../../shared/constants/app_colors.dart';
import '../../data/models/chat_session.dart';
import 'chat_history_item.dart';

class ChatHistoryList extends StatelessWidget {
  final List<ChatSession> chats;
  final ChatSession? current;
  final void Function(ChatSession chat) onTapChat;

  const ChatHistoryList({
    super.key,
    required this.chats,
    required this.current,
    required this.onTapChat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatHistoryItem(
          chat: chat,
          isSelected: current?.id == chat.id,
          onTap: () => onTapChat(chat),
        );
      },
    );
  }
}
