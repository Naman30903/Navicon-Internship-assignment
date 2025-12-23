import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';
import 'package:frontend/models/task_model.dart';
import '../ui/priority_style.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priorityStyle = PriorityStyle.from(theme, task.priority);

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title?.trim().isNotEmpty == true
                        ? task.title!.trim()
                        : 'Untitled',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                _PriorityBadge(
                  label: task.priority,
                  background: priorityStyle.background,
                  foreground: priorityStyle.foreground,
                  border: priorityStyle.border,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                _CategoryChip(category: task.category),
                _StatusChip(status: task.status),
              ],
            ),
            if ((task.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text(
                task.description!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final label = category.trim().isEmpty
        ? 'general'
        : category.trim().toLowerCase();

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: cs.onSecondaryContainer,
      ),
      backgroundColor: cs.secondaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final normalized = status.trim().isEmpty ? 'pending' : status.trim();
    final pretty = _prettyStatus(normalized);

    final color = switch (normalized) {
      'completed' => cs.secondary,
      'in_progress' => cs.primary,
      _ => cs.tertiary,
    };

    return Chip(
      label: Text(pretty),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.30)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _prettyStatus(String s) {
    switch (s) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const _PriorityBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = label.trim().isEmpty
        ? 'low'
        : label.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        normalized,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
