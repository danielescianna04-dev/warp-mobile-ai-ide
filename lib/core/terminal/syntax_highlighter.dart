import 'package:flutter/material.dart';

class TerminalSyntaxHighlighter {
  static const Map<String, Color> _commandColors = {
    // Git commands - Orange
    'git': Color(0xFFFF8C00),
    
    // NPM/Yarn - Red
    'npm': Color(0xFFE53E3E),
    'yarn': Color(0xFF3182CE),
    
    // Flutter - Blue
    'flutter': Color(0xFF02569B),
    
    // Docker - Blue
    'docker': Color(0xFF2496ED),
    'docker-compose': Color(0xFF2496ED),
    
    // System commands - Green
    'cd': Color(0xFF38A169),
    'ls': Color(0xFF38A169),
    'pwd': Color(0xFF38A169),
    'mkdir': Color(0xFF38A169),
    'rm': Color(0xFFE53E3E),
    'rmdir': Color(0xFFE53E3E),
    'cp': Color(0xFF3182CE),
    'mv': Color(0xFF3182CE),
    'cat': Color(0xFF805AD5),
    'grep': Color(0xFF805AD5),
    'find': Color(0xFF805AD5),
    'which': Color(0xFF805AD5),
    'whereis': Color(0xFF805AD5),
    'clear': Color(0xFF718096),
    'exit': Color(0xFFE53E3E),
    
    // Build tools - Yellow
    'make': Color(0xFFD69E2E),
    'cmake': Color(0xFFD69E2E),
    'gradle': Color(0xFFD69E2E),
    'maven': Color(0xFFD69E2E),
    'webpack': Color(0xFFD69E2E),
    'vite': Color(0xFFD69E2E),
    'rollup': Color(0xFFD69E2E),
    
    // Editors - Purple
    'code': Color(0xFF805AD5),
    'vim': Color(0xFF805AD5),
    'nano': Color(0xFF805AD5),
    
    // Network tools - Cyan
    'curl': Color(0xFF00B5D8),
    'wget': Color(0xFF00B5D8),
    'ssh': Color(0xFF00B5D8),
    'scp': Color(0xFF00B5D8),
    'rsync': Color(0xFF00B5D8),
    
    // Package managers - Pink
    'pip': Color(0xFFED64A6),
    'brew': Color(0xFFED64A6),
    'apt': Color(0xFFED64A6),
    'yum': Color(0xFFED64A6),
  };

  static List<TextSpan> highlightCommand(String command, Color defaultTextColor) {
    if (command.isEmpty) {
      return [TextSpan(text: command, style: TextStyle(color: defaultTextColor))];
    }

    List<TextSpan> spans = [];
    List<String> parts = command.split(' ');
    
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      
      if (i > 0) {
        spans.add(TextSpan(text: ' ', style: TextStyle(color: defaultTextColor)));
      }
      
      // Highlight the main command and subcommands
      Color textColor = defaultTextColor;
      FontWeight fontWeight = FontWeight.normal;
      
      if (i == 0) {
        // Main command
        textColor = _commandColors[part.toLowerCase()] ?? defaultTextColor;
        fontWeight = FontWeight.w600;
      } else if (i == 1 && _commandColors.containsKey('${parts[0].toLowerCase()} ${part.toLowerCase()}')) {
        // Subcommand (like 'npm run', 'git add', etc.)
        textColor = _commandColors['${parts[0].toLowerCase()} ${part.toLowerCase()}'] ?? 
                   _commandColors[parts[0].toLowerCase()] ?? 
                   defaultTextColor;
        fontWeight = FontWeight.w500;
      } else {
        // Arguments and flags
        if (part.startsWith('-')) {
          // Flags and options
          textColor = const Color(0xFF9F7AEA); // Purple for flags
        } else if (part.contains('/') || part.contains('.')) {
          // Paths and filenames
          textColor = const Color(0xFF48BB78); // Green for paths
        } else if (RegExp(r'^\d+$').hasMatch(part)) {
          // Numbers
          textColor = const Color(0xFF3182CE); // Blue for numbers
        } else if (part.startsWith('"') && part.endsWith('"') || 
                   part.startsWith("'") && part.endsWith("'")) {
          // Strings
          textColor = const Color(0xFF38B2AC); // Teal for strings
        }
      }
      
      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
          fontFamily: 'SF Mono',
        ),
      ));
    }
    
    return spans;
  }

  static List<TextSpan> highlightOutput(String output, Color defaultTextColor) {
    if (output.isEmpty) {
      return [TextSpan(text: output, style: TextStyle(color: defaultTextColor))];
    }

    List<TextSpan> spans = [];
    List<String> lines = output.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      String line = lines[lineIndex];
      
      if (lineIndex > 0) {
        spans.add(TextSpan(text: '\n', style: TextStyle(color: defaultTextColor)));
      }
      
      // Highlight different types of output
      if (line.toLowerCase().contains('error')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: const Color(0xFFE53E3E), // Red for errors
            fontFamily: 'SF Mono',
          ),
        ));
      } else if (line.toLowerCase().contains('warning')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: const Color(0xFFD69E2E), // Yellow for warnings
            fontFamily: 'SF Mono',
          ),
        ));
      } else if (line.toLowerCase().contains('success') || 
                 line.toLowerCase().contains('done') ||
                 line.toLowerCase().contains('completed')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: const Color(0xFF38A169), // Green for success
            fontFamily: 'SF Mono',
          ),
        ));
      } else if (line.startsWith('├─') || line.startsWith('└─') || line.startsWith('│')) {
        // Tree structure (like npm ls output)
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: const Color(0xFF718096), // Gray for tree structure
            fontFamily: 'SF Mono',
          ),
        ));
      } else {
        // Regular output with potential highlighting of paths and files
        spans.addAll(_highlightPathsInLine(line, defaultTextColor));
      }
    }
    
    return spans;
  }

  static List<TextSpan> _highlightPathsInLine(String line, Color defaultTextColor) {
    List<TextSpan> spans = [];
    
    // Simple regex to match file paths and URLs
    RegExp pathRegex = RegExp(r'[^\s]+\.[a-zA-Z]+|\/[^\s]+|https?:\/\/[^\s]+');
    
    int lastEnd = 0;
    
    for (Match match in pathRegex.allMatches(line)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: TextStyle(color: defaultTextColor, fontFamily: 'SF Mono'),
        ));
      }
      
      // Add the highlighted match
      String matchText = match.group(0)!;
      Color color = defaultTextColor;
      
      if (matchText.startsWith('http')) {
        color = const Color(0xFF3182CE); // Blue for URLs
      } else if (matchText.startsWith('/')) {
        color = const Color(0xFF48BB78); // Green for absolute paths
      } else if (matchText.contains('.')) {
        color = const Color(0xFF38B2AC); // Teal for files with extensions
      }
      
      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: color,
          fontFamily: 'SF Mono',
          decoration: matchText.startsWith('http') ? TextDecoration.underline : null,
        ),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: TextStyle(color: defaultTextColor, fontFamily: 'SF Mono'),
      ));
    }
    
    // If no matches, return the whole line
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: line,
        style: TextStyle(color: defaultTextColor, fontFamily: 'SF Mono'),
      ));
    }
    
    return spans;
  }
}