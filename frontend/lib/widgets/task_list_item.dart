import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';
import 'package:frontend/models/task_model.dart';
import 'package:frontend/riverpod/task_provider.dart';
import 'package:frontend/widgets/task_card.dart';
import 'package:frontend/screens/tasks_detail.dart';

class TaskListItem extends ConsumerWidget {
  final TaskModel task;
  final VoidCallback onDeleteSuccess;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => _handleDelete(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Icon(Icons.delete, color: cs.error),
      ),
      child: TaskCard(
        task: task,
        onTap: () => TaskDetailsSheet.show(context, ref, task),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete task?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(deleteTaskProvider.notifier).deleteTask(task.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      onDeleteSuccess();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Re-fetch to restore if delete failed
      ref.invalidate(taskListProvider);
    }
  }
}
