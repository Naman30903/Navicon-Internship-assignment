import 'package:flutter/foundation.dart';
import '../constant/task_sort.dart';

@immutable
class FilterState {
  final String? status;
  final String? category;
  final String? priority;
  final TaskSort sort;

  const FilterState({
    required this.status,
    required this.category,
    required this.priority,
    required this.sort,
  });

  FilterState copyWith({
    String? status,
    String? category,
    String? priority,
    TaskSort? sort,
  }) {
    return FilterState(
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters =>
      status != null || category != null || priority != null;
}