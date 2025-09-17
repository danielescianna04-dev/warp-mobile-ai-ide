import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'syntax_highlighter.dart';

class SyntaxHighlightingController extends TextEditingController {
  final Color defaultTextColor;
  final bool isTerminalMode;

  SyntaxHighlightingController({
    required this.defaultTextColor,
    required this.isTerminalMode,
    String? text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!isTerminalMode || text.isEmpty) {
      return TextSpan(
        text: text,
        style: style,
      );
    }

    // Get highlighted spans for the current text
    List<TextSpan> spans = TerminalSyntaxHighlighter.highlightCommand(text, defaultTextColor);
    
    // Apply the base style to all spans
    List<TextSpan> styledSpans = spans.map((span) {
      return TextSpan(
        text: span.text,
        style: style?.merge(span.style) ?? span.style,
      );
    }).toList();

    return TextSpan(children: styledSpans);
  }
}

class SyntaxTextField extends StatefulWidget {
  final SyntaxHighlightingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final int? maxLines;
  final BoxConstraints? constraints;

  const SyntaxTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.hintStyle,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
    this.maxLines,
    this.constraints,
  });

  @override
  State<SyntaxTextField> createState() => _SyntaxTextFieldState();
}

class _SyntaxTextFieldState extends State<SyntaxTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Force rebuild to update syntax highlighting
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: widget.style,
      maxLines: widget.maxLines,
      decoration: widget.decoration?.copyWith(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
      ) ?? InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.newline,
    );

    if (widget.constraints != null) {
      return ConstrainedBox(
        constraints: widget.constraints!,
        child: textField,
      );
    }

    return textField;
  }
}