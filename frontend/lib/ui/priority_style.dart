import 'package:flutter/material.dart';

class PriorityStyle {
  final Color background;
  final Color foreground;
  final Color border;

  const PriorityStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  factory PriorityStyle.from(ThemeData theme, String priority) {
    final cs = theme.colorScheme;
    final p = priority.trim().isEmpty ? 'low' : priority.trim().toLowerCase();

    switch (p) {
      case 'high':
        return PriorityStyle(
          background: cs.errorContainer,
          foreground: cs.onErrorContainer,
          border: cs.error.withValues(alpha: 0.35),
        );
      case 'medium':
        return PriorityStyle(
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
          border: cs.tertiary.withValues(alpha: 0.35),
        );
      case 'low':
      default:
        return PriorityStyle(
          background: cs.secondaryContainer,
          foreground: cs.onSecondaryContainer,
          border: cs.secondary.withValues(alpha: 0.35),
        );
    }
  }
}
