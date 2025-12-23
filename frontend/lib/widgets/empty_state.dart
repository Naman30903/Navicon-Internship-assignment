import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxl),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.outline),
          const SizedBox(height: AppSpace.md),
          Text(
            'No tasks yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Tap + to create your first task.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
