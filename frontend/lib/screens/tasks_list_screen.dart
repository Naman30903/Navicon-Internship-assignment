import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/riverpod/task_provider.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = TaskFilters(limit: 20, offset: 0);
    final tasksAsync = ref.watch(taskListProvider(filters));

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: tasksAsync.when(
        data: (tasks) => ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.title ?? 'Untitled'),
              subtitle: Text(task.status),
              trailing: Text(task.priority),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Example: Create a task
          await ref
              .read(createTaskProvider.notifier)
              .createTask(
                title: 'New Task',
                description: 'Task description',
                priority: 'high',
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
