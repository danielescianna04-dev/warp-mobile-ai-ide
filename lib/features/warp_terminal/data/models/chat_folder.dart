import 'package:flutter/material.dart';

// Modello per cartelle chat
class ChatFolder {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final DateTime createdAt;
  
  ChatFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ChatFolder.fromJson(Map<String, dynamic> json) {
    return ChatFolder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📁',
      color: Color(json['color'] ?? 0xFF6B73FF),
      createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
    );
  }

  // Copy with method for updates
  ChatFolder copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    DateTime? createdAt,
  }) {
    return ChatFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}