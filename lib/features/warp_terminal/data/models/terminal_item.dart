// Terminal item type
enum TerminalItemType {
  command,
  output,
  error,
  system,
}

// Terminal item model
class TerminalItem {
  final String content;
  final TerminalItemType type;
  final DateTime timestamp;

  TerminalItem({
    required this.content,
    required this.type,
    required this.timestamp,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from JSON
  factory TerminalItem.fromJson(Map<String, dynamic> json) {
    return TerminalItem(
      content: json['content'] ?? '',
      type: TerminalItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TerminalItemType.output,
      ),
      timestamp: DateTime.tryParse(json['timestamp']) ?? DateTime.now(),
    );
  }
}