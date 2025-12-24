import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';
import 'package:frontend/models/task_model.dart'; // <-- add
import 'package:frontend/riverpod/task_provider.dart';

import '../ui/status_count.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_row.dart';
import '../widgets/task_card.dart';
import '../ui/task_list_layout.dart';
import 'tasks_detail.dart';

enum TaskSort { newestFirst, oldestFirst, dueDate }

extension _TaskSortLabel on TaskSort {
  String get label => switch (this) {
    TaskSort.newestFirst => 'Newest first',
    TaskSort.oldestFirst => 'Oldest first',
    TaskSort.dueDate => 'Due date',
  };
}

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchCtrl = TextEditingController();

  String? _status; // pending/in_progress/completed
  String? _category; // general/technical/finance/scheduling/safety
  String? _priority; // low/medium/high
  TaskSort _sort = TaskSort.newestFirst;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            final filtered = _applyClientFilters(tasks); // now List<TaskModel>
            final counts = StatusCounts.fromTasks(filtered);

            return TaskListLayout(
              summary: Column(
                children: [
                  _SearchAndFiltersBar(
                    searchController: _searchCtrl,
                    status: _status,
                    category: _category,
                    priority: _priority,
                    sort: _sort,
                    onChanged: (next) {
                      setState(() {
                        _status = next.status;
                        _category = next.category;
                        _priority = next.priority;
                        _sort = next.sort;
                      });
                    },
                    onSearchChanged: (_) => setState(() {}),
                    onClearAll: () {
                      setState(() {
                        _searchCtrl.clear();
                        _status = null;
                        _category = null;
                        _priority = null;
                        _sort = TaskSort.newestFirst;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                  SummaryRow(counts: counts),
                ],
              ),
              body: filtered.isEmpty
                  ? const SliverToBoxAdapter(child: EmptyState())
                  : SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpace.md),
                      itemBuilder: (context, index) {
                        final task = filtered[index];

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

  List<TaskModel> _applyClientFilters(List<TaskModel> tasks) {
    final q = _searchCtrl.text.trim().toLowerCase();

    bool matchesSearch(TaskModel t) {
      final title = (t.title ?? '').toLowerCase();
      final desc = (t.description ?? '').toLowerCase();
      if (q.isEmpty) return true;
      return title.contains(q) || desc.contains(q);
    }

    bool matchesEquals(String? value, String actual) {
      if (value == null) return true;
      return value == actual;
    }

    final list = tasks.where((t) {
      return matchesSearch(t) &&
          matchesEquals(_status, t.status) &&
          matchesEquals(_category, t.category) &&
          matchesEquals(_priority, t.priority);
    }).toList();

    DateTime? dueDate(TaskModel t) {
      final iso = t.dueDate;
      if (iso == null || iso.trim().isEmpty) return null;
      return DateTime.tryParse(iso);
    }

    list.sort((a, b) {
      switch (_sort) {
        case TaskSort.newestFirst:
          return b.createdAt.compareTo(a.createdAt);
        case TaskSort.oldestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case TaskSort.dueDate:
          final ad = dueDate(a);
          final bd = dueDate(b);

          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
      }
    });

    return list;
  }
}

@immutable
class _FilterState {
  final String? status;
  final String? category;
  final String? priority;
  final TaskSort sort;

  const _FilterState({
    required this.status,
    required this.category,
    required this.priority,
    required this.sort,
  });
}

class _SearchAndFiltersBar extends StatelessWidget {
  final TextEditingController searchController;

  final String? status;
  final String? category;
  final String? priority;
  final TaskSort sort;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_FilterState> onChanged;
  final VoidCallback onClearAll;

  const _SearchAndFiltersBar({
    required this.searchController,
    required this.status,
    required this.category,
    required this.priority,
    required this.sort,
    required this.onSearchChanged,
    required this.onChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search title or description…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChipMenu<String?>(
                label: 'Status',
                value: status,
                items: const [null, 'pending', 'in_progress', 'completed'],
                itemLabel: (v) => v == null
                    ? 'Any'
                    : (v == 'in_progress'
                          ? 'In Progress'
                          : '${v[0].toUpperCase()}${v.substring(1)}'),
                onSelected: (v) => onChanged(
                  _FilterState(
                    status: v,
                    category: category,
                    priority: priority,
                    sort: sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<String?>(
                label: 'Category',
                value: category,
                items: const [
                  null,
                  'general',
                  'technical',
                  'finance',
                  'scheduling',
                  'safety',
                ],
                itemLabel: (v) => v ?? 'Any',
                onSelected: (v) => onChanged(
                  _FilterState(
                    status: status,
                    category: v,
                    priority: priority,
                    sort: sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<String?>(
                label: 'Priority',
                value: priority,
                items: const [null, 'low', 'medium', 'high'],
                itemLabel: (v) => v ?? 'Any',
                onSelected: (v) => onChanged(
                  _FilterState(
                    status: status,
                    category: category,
                    priority: v,
                    sort: sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<TaskSort>(
                label: 'Sort',
                value: sort,
                items: const [
                  TaskSort.newestFirst,
                  TaskSort.oldestFirst,
                  TaskSort.dueDate,
                ],
                itemLabel: (v) => v.label,
                onSelected: (v) => onChanged(
                  _FilterState(
                    status: status,
                    category: category,
                    priority: priority,
                    sort: v,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(Icons.filter_alt_off, color: cs.primary),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipMenu<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  const _ChipMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final current = itemLabel(value);

    return MenuAnchor(
      builder: (context, controller, child) {
        return ActionChip(
          label: Text('$label: $current'),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          labelStyle: theme.textTheme.labelLarge,
        );
      },
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: () => onSelected(item),
            child: Text(itemLabel(item)),
          ),
      ],
    );
  }
}
