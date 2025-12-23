import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';
import 'package:frontend/ui/status_count.dart';

class SummaryRow extends StatelessWidget {
  final StatusCounts counts;

  const SummaryRow({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 520;

        final children = <Widget>[
          Expanded(
            child: _SummaryStatCard(
              label: 'Pending',
              value: counts.pending,
              icon: Icons.schedule,
              accent: cs.tertiary,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _SummaryStatCard(
              label: 'In Progress',
              value: counts.inProgress,
              icon: Icons.autorenew,
              accent: cs.primary,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _SummaryStatCard(
              label: 'Completed',
              value: counts.completed,
              icon: Icons.check_circle,
              accent: cs.secondary,
            ),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(children: [children[0]]),
              const SizedBox(height: AppSpace.md),
              Row(children: [children[2]]),
              const SizedBox(height: AppSpace.md),
              Row(children: [children[4]]),
            ],
          );
        }

        return Row(children: children);
      },
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '$value',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
