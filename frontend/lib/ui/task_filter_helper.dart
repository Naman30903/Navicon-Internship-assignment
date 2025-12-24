import 'package:frontend/constant/task_sort.dart';
import 'package:frontend/models/task_model.dart';

class TaskFilterHelper {
  static List<TaskModel> applyFilters({
    required List<TaskModel> tasks,
    required String searchQuery,
    String? status,
    String? category,
    String? priority,
    required TaskSort sort,
  }) {
    final q = searchQuery.trim().toLowerCase();

    // Filter
    final filtered = tasks.where((t) {
      final matchesSearch = _matchesSearch(t, q);
      final matchesStatus = status == null || t.status == status;
      final matchesCategory = category == null || t.category == category;
      final matchesPriority = priority == null || t.priority == priority;

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesPriority;
    }).toList();

    // Sort
    filtered.sort((a, b) => _compareBySort(a, b, sort));

    return filtered;
  }

  static bool _matchesSearch(TaskModel task, String query) {
    if (query.isEmpty) return true;
    final title = (task.title ?? '').toLowerCase();
    final desc = (task.description ?? '').toLowerCase();
    return title.contains(query) || desc.contains(query);
  }

  static int _compareBySort(TaskModel a, TaskModel b, TaskSort sort) {
    switch (sort) {
      case TaskSort.newestFirst:
        return b.createdAt.compareTo(a.createdAt);
      case TaskSort.oldestFirst:
        return a.createdAt.compareTo(b.createdAt);
      case TaskSort.dueDate:
        return _compareDueDate(a, b);
    }
  }

  static int _compareDueDate(TaskModel a, TaskModel b) {
    final ad = _parseDueDate(a.dueDate);
    final bd = _parseDueDate(b.dueDate);

    if (ad == null && bd == null) return 0;
    if (ad == null) return 1; // nulls last
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  static DateTime? _parseDueDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
