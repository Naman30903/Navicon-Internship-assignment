import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';
import 'package:frontend/riverpod/task_provider.dart';

import '../ui/status_count.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_row.dart';
import '../widgets/task_card.dart';
import '../ui/task_list_layout.dart';
import 'tasks_detail.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = TaskFilters(limit: 20, offset: 0);
    final tasksAsync = ref.watch(taskListProvider(filters));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: tasksAsync.when(
          data: (tasks) {
            final counts = StatusCounts.fromTasks(tasks);

            return TaskListLayout(
              summary: SummaryRow(counts: counts),
              body: tasks.isEmpty
                  ? const EmptyState()
                  : SliverList.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpace.md),
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return Dismissible(
                          key: ValueKey(task.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete task?'),
                                    content: const Text(
                                      'This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) async {
                            await ref
                                .read(deleteTaskProvider.notifier)
                                .deleteTask(task.id);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task deleted')),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                            ),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                            ),
                            child: Icon(Icons.delete, color: cs.error),
                          ),
                          child: TaskCard(
                            task: task,
                            onTap: () =>
                                TaskDetailsSheet.show(context, ref, task),
                          ),
                        );
                      },
                    ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Text(
                'Error: $error',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreateTaskSheet.show(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
