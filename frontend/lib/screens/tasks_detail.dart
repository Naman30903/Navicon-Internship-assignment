import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/models/task_model.dart';
import 'package:frontend/screens/edit_task.dart';

class TaskDetailsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppSpace.horizontalPaddingForWidth(maxWidth);

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
              _ReadOnlyField(label: 'Due date', value: task.dueDate ?? '—'),

              const SizedBox(height: AppSpace.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    // close details sheet
                    Navigator.of(context).pop();

                    // open edit sheet
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
            ],
          ),
        ),
      ),
    );
  }
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
