import 'terminal_item.dart';

// Modello per sessioni di chat
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUsed;
  final List<TerminalItem> messages;
  final String aiModel;
  final String? folderId;
  final String? repositoryId; // ID della repository GitHub associata
  final String? repositoryName; // Nome della repository per display
  
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUsed,
    required this.messages,
    required this.aiModel,
    this.folderId,
    this.repositoryId,
    this.repositoryName,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'aiModel': aiModel,
      'folderId': folderId,
      'repositoryId': repositoryId,
      'repositoryName': repositoryName,
    };
  }

  // Create from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      lastUsed: DateTime.tryParse(json['lastUsed']) ?? DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => TerminalItem.fromJson(m))
          .toList() ?? [],
      aiModel: json['aiModel'] ?? 'claude-4-sonnet',
      folderId: json['folderId'],
      repositoryId: json['repositoryId'],
      repositoryName: json['repositoryName'],
    );
  }

  // Copy with method for updates
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUsed,
    List<TerminalItem>? messages,
    String? aiModel,
    String? folderId,
    String? repositoryId,
    String? repositoryName,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      messages: messages ?? this.messages,
      aiModel: aiModel ?? this.aiModel,
      folderId: folderId ?? this.folderId,
      repositoryId: repositoryId ?? this.repositoryId,
      repositoryName: repositoryName ?? this.repositoryName,
    );
  }
}