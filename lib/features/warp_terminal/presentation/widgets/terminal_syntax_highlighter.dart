import 'package:flutter/material.dart';

class TerminalSyntaxHighlighter {
  static List<TextSpan> highlightCommand(String text, Color baseColor) {
    final List<TextSpan> spans = [];
    final words = text.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      Color color = baseColor;
      FontWeight weight = FontWeight.normal;
      
      // Highlight command (first word)
      if (i == 0) {
        color = const Color(0xFF06B6D4);
        weight = FontWeight.w600;
      }
      // Highlight flags (starting with -)
      else if (word.startsWith('-')) {
        color = const Color(0xFF10B981);
      }
      // Highlight file paths
      else if (word.contains('/') || word.contains('.')) {
        color = const Color(0xFFF59E0B);
      }
      
      spans.add(TextSpan(
        text: i == 0 ? word : ' $word',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontFamily: 'SF Mono',
          fontWeight: weight,
          height: 1.4,
        ),
      ));
    }
    
    return spans;
  }
  
  static List<TextSpan> highlightOutput(String text, Color baseColor) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      
      // Error patterns
      if (line.toLowerCase().contains('error') || 
          line.toLowerCase().contains('failed') ||
          line.toLowerCase().contains('exception')) {
        spans.add(TextSpan(
          text: lineIndex == 0 ? line : '\n$line',
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 14,
            fontFamily: 'SF Mono',
            height: 1.4,
          ),
        ));
      }
      // Warning patterns
      else if (line.toLowerCase().contains('warning') ||
               line.toLowerCase().contains('warn')) {
        spans.add(TextSpan(
          text: lineIndex == 0 ? line : '\n$line',
          style: const TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 14,
            fontFamily: 'SF Mono',
            height: 1.4,
          ),
        ));
      }
      // Success patterns
      else if (line.toLowerCase().contains('success') ||
               line.toLowerCase().contains('done') ||
               line.toLowerCase().contains('completed')) {
        spans.add(TextSpan(
          text: lineIndex == 0 ? line : '\n$line',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 14,
            fontFamily: 'SF Mono',
            height: 1.4,
          ),
        ));
      }
      // URLs
      else if (line.contains('http://') || line.contains('https://')) {
        spans.add(TextSpan(
          text: lineIndex == 0 ? line : '\n$line',
          style: const TextStyle(
            color: Color(0xFF06B6D4),
            fontSize: 14,
            fontFamily: 'SF Mono',
            height: 1.4,
            decoration: TextDecoration.underline,
          ),
        ));
      }
      // Default output
      else {
        spans.add(TextSpan(
          text: lineIndex == 0 ? line : '\n$line',
          style: TextStyle(
            color: baseColor,
            fontSize: 14,
            fontFamily: 'SF Mono',
            height: 1.4,
          ),
        ));
      }
    }
    
    return spans;
  }
}