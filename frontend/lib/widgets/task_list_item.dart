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
  final String highlightQuery;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onDeleteSuccess,
    this.highlightQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await _showDeleteConfirmation(context);
        if (!confirmed) return false;

        try {
          await ref.read(deleteTaskProvider.notifier).deleteTask(task.id);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Task deleted')));
          });

          onDeleteSuccess();
          return true;
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_uiError(e)),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          });
          return false;
        }
      },
      // no onDismissed: delete is handled in confirmDismiss to avoid double-call
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
        highlightQuery: highlightQuery,
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

  String _uiError(Object err) {
    final s = err.toString();
    return s.startsWith('Exception: ') ? s.replaceFirst('Exception: ', '') : s;
  }
}
