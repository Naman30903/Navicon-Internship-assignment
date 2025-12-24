import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final cs = Theme.of(context).colorScheme;
    final hiStyle =
        highlightStyle ??
        baseStyle.copyWith(
          backgroundColor: cs.primary.withValues(alpha: 0.22),
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
        );

    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = _buildSpans(text, q, baseStyle, hiStyle);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildSpans(
    String source,
    String query,
    TextStyle base,
    TextStyle hi,
  ) {
    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerSource.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: source.substring(start), style: base));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: source.substring(start, index), style: base));
      }

      spans.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: hi,
        ),
      );

      start = index + query.length;
    }

    return spans;
  }
}
