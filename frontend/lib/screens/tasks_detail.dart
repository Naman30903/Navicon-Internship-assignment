import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/models/task_model.dart';
import 'package:frontend/models/task_history.dart';
import 'package:frontend/riverpod/task_provider.dart';
import 'package:frontend/screens/edit_task.dart';
import 'package:timeago/timeago.dart' as timeago;

class TaskDetailsSheet extends ConsumerWidget {
  final TaskModel task;

  const TaskDetailsSheet({super.key, required this.task});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskDetailsSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppSpace.horizontalPaddingForWidth(maxWidth);

    final historyAsync = ref.watch(taskHistoryProvider(task.id));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpace.lg,
            horizontalPadding,
            AppSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              _ReadOnlyField(label: 'Title', value: task.title ?? '—'),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(
                label: 'Description',
                value: (task.description ?? '').trim().isEmpty
                    ? '—'
                    : task.description!.trim(),
                multiline: true,
              ),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(label: 'Status', value: task.status),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(label: 'Category', value: task.category),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(label: 'Priority', value: task.priority),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(
                label: 'Assigned to',
                value: (task.assignedTo ?? '').trim().isEmpty
                    ? '—'
                    : task.assignedTo!.trim(),
              ),
              const SizedBox(height: AppSpace.md),
              _ReadOnlyField(
                label: 'Due date',
                value: _formatDueDate(task.dueDate),
              ),

              const SizedBox(height: AppSpace.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await EditTaskSheet.show(context, task: task);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),

              const SizedBox(height: AppSpace.sm),
              Text(
                'Read-only preview. Tap Edit to update.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: AppSpace.xl),

              // History Section
              Row(
                children: [
                  Icon(Icons.history, size: 20, color: cs.primary),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              historyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpace.lg),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          'Failed to load history',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (history) {
                  if (history.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No history available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return _HistoryTimeline(history: history);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDueDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';

    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<TaskHistory> history;

  const _HistoryTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < history.length; i++)
          _HistoryItem(history: history[i], isLast: i == history.length - 1),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final TaskHistory history;
  final bool isLast;

  const _HistoryItem({required this.history, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2),
                ),
                child: Icon(
                  history.actionIcon,
                  size: 16,
                  color: cs.onPrimaryContainer,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.md),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        history.actionLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(history.changedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'by ${history.changedBy}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (_shouldShowChanges(history)) ...[
                    const SizedBox(height: AppSpace.sm),
                    _ChangesSummary(history: history),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowChanges(TaskHistory history) {
    return history.action == 'updated' || history.action == 'status_changed';
  }
}

class _ChangesSummary extends StatelessWidget {
  final TaskHistory history;

  const _ChangesSummary({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final changes = _extractChanges();
    if (changes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${change.field}: ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: change.oldValue,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: cs.error,
                            ),
                          ),
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: change.newValue,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_FieldChange> _extractChanges() {
    final changes = <_FieldChange>[];

    if (history.oldValue == null || history.newValue == null) {
      return changes;
    }

    final oldVal = history.oldValue!;
    final newVal = history.newValue!;

    // Compare common fields
    for (final key in ['title', 'status', 'priority', 'category']) {
      if (oldVal[key] != newVal[key] && newVal[key] != null) {
        changes.add(
          _FieldChange(
            field: _capitalize(key),
            oldValue: oldVal[key]?.toString() ?? '—',
            newValue: newVal[key]?.toString() ?? '—',
          ),
        );
      }
    }

    return changes;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _FieldChange {
  final String field;
  final String oldValue;
  final String newValue;

  _FieldChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
  });
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
            maxLines: multiline ? 10 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
