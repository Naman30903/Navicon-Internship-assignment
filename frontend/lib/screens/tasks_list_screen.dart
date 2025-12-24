import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/riverpod/connectivity_provider.dart';
import 'package:frontend/riverpod/task_provider.dart';
import 'package:frontend/models/filter.dart';
import 'package:frontend/ui/skeleton_box.dart';
import 'package:frontend/ui/status_count.dart';
import 'package:frontend/ui/task_filter_helper.dart';
import 'package:frontend/ui/task_list_layout.dart';
import 'package:frontend/widgets/create_task_sheet.dart';
import 'package:frontend/widgets/empty_state.dart';
import 'package:frontend/widgets/search_filter.dart';
import 'package:frontend/widgets/server_banner.dart';
import 'package:frontend/widgets/summary_row.dart';

import '../constant/task_sort.dart';
import '../riverpod/theme_provider.dart';
import '../widgets/offline_banner.dart';
import '../widgets/task_list_item.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchCtrl = TextEditingController();
  FilterState _filters = const FilterState(
    status: null,
    category: null,
    priority: null,
    sort: TaskSort.newestFirst,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const apiFilters = TaskFilters(limit: 20, offset: 0);
    final tasksAsync = ref.watch(taskListProvider(apiFilters));
    final isOffline = ref.watch(isOfflineProvider);

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Listen for task list errors
    ref.listen<AsyncValue<dynamic>>(taskListProvider(apiFilters), (prev, next) {
      next.whenOrNull(
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage(err)),
              backgroundColor: cs.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: cs.onError,
                onPressed: () => ref.invalidate(taskListProvider(apiFilters)),
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isOffline) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(taskListProvider(apiFilters));
                  await ref.read(taskListProvider(apiFilters).future);
                },
                child: tasksAsync.when(
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error, apiFilters),
                  data: (tasks) => _buildDataState(tasks),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreateTaskSheet.show(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return TaskListLayout(
      summary: Column(
        children: [
          SearchFiltersBar(
            searchController: _searchCtrl,
            filters: _filters,
            onSearchChanged: (_) => setState(() {}),
            onFiltersChanged: (f) => setState(() => _filters = f),
            onClearAll: _clearFilters,
          ),
          const SizedBox(height: AppSpace.md),
          const SummaryRowSkeleton(),
        ],
      ),
      body: const TaskListSkeletonSliver(itemCount: 6),
    );
  }

  Widget _buildErrorState(Object error, TaskFilters apiFilters) {
    return TaskListLayout(
      summary: Column(
        children: [
          SearchFiltersBar(
            searchController: _searchCtrl,
            filters: _filters,
            onSearchChanged: (_) => setState(() {}),
            onFiltersChanged: (f) => setState(() => _filters = f),
            onClearAll: _clearFilters,
          ),
          const SizedBox(height: AppSpace.md),
          ServerErrorBanner(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(taskListProvider(apiFilters)),
          ),
        ],
      ),
      body: const SliverToBoxAdapter(child: SizedBox(height: 1)),
    );
  }

  Widget _buildDataState(List<dynamic> tasks) {
    final filtered = TaskFilterHelper.applyFilters(
      tasks: tasks.cast(),
      searchQuery: _searchCtrl.text,
      status: _filters.status,
      category: _filters.category,
      priority: _filters.priority,
      sort: _filters.sort,
    );

    final counts = StatusCounts.fromTasks(filtered);

    return TaskListLayout(
      summary: Column(
        children: [
          SearchFiltersBar(
            searchController: _searchCtrl,
            filters: _filters,
            onSearchChanged: (_) => setState(() {}),
            onFiltersChanged: (f) => setState(() => _filters = f),
            onClearAll: _clearFilters,
          ),
          const SizedBox(height: AppSpace.md),
          SummaryRow(counts: counts),
        ],
      ),
      body: filtered.isEmpty
          ? const SliverToBoxAdapter(child: EmptyState())
          : SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
              itemBuilder: (context, index) {
                return TaskListItem(
                  task: filtered[index],
                  onDeleteSuccess: () {},
                  highlightQuery: _searchCtrl.text,
                );
              },
            ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _filters = const FilterState(
        status: null,
        category: null,
        priority: null,
        sort: TaskSort.newestFirst,
      );
    });
  }

  String _errorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('DioException') && raw.toLowerCase().contains('socket')) {
      return 'No internet connection. Please try again.';
    }
    if (raw.contains('timed out') || raw.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }
    return raw.startsWith('Exception: ')
        ? raw.replaceFirst('Exception: ', '')
        : raw;
  }
}
