import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/task_classification_model.dart';
import '../api/api_client.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Task Repository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TaskRepository(apiClient);
});

// Task List Provider (with filters)
final taskListProvider = FutureProvider.autoDispose
    .family<List<TaskModel>, TaskFilters>((ref, filters) async {
      final repository = ref.watch(taskRepositoryProvider);
      final response = await repository.fetchTasks(
        limit: filters.limit,
        offset: filters.offset,
        status: filters.status,
        category: filters.category,
        priority: filters.priority,
      );
      return response.tasks;
    });

// Single Task Provider
final taskByIdProvider = FutureProvider.autoDispose.family<TaskModel, String>((
  ref,
  id,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskById(id);
});

// Create Task Provider (async notifier for mutations)
final createTaskProvider =
    AsyncNotifierProvider<CreateTaskNotifier, TaskModel?>(
      CreateTaskNotifier.new,
    );

class CreateTaskNotifier extends AsyncNotifier<TaskModel?> {
  @override
  Future<TaskModel?> build() async {
    return null;
  }

  Future<void> createTask({
    String? title,
    String? description,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskRepositoryProvider);
      final task = await repository.createTask(
        title: title,
        description: description,
        status: status,
        category: category,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
      );
      // Invalidate task list to refresh after creation
      ref.invalidate(taskListProvider);
      return task;
    });
  }
}

// Update Task Provider
final updateTaskProvider =
    AsyncNotifierProvider<UpdateTaskNotifier, TaskModel?>(
      UpdateTaskNotifier.new,
    );

class UpdateTaskNotifier extends AsyncNotifier<TaskModel?> {
  @override
  Future<TaskModel?> build() async {
    return null;
  }

  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskRepositoryProvider);
      final task = await repository.updateTask(
        id,
        title: title,
        description: description,
        status: status,
        category: category,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
      );
      ref.invalidate(taskListProvider);
      ref.invalidate(taskByIdProvider(id));
      return task;
    });
  }
}

// Delete Task Provider
final deleteTaskProvider = AsyncNotifierProvider<DeleteTaskNotifier, bool>(
  DeleteTaskNotifier.new,
);

class DeleteTaskNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskRepositoryProvider);
      await repository.deleteTask(id);
      // Invalidate task list after deletion
      ref.invalidate(taskListProvider);
      return true;
    });
  }
}

// Classify Task Provider
final classifyTaskProvider =
    AsyncNotifierProvider<ClassifyTaskNotifier, TaskClassification?>(
      ClassifyTaskNotifier.new,
    );

class ClassifyTaskNotifier extends AsyncNotifier<TaskClassification?> {
  @override
  Future<TaskClassification?> build() async => null;

  Future<void> classify({required String description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(taskRepositoryProvider);
      return repo.classifyTask(description: description);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Filter model for task list
class TaskFilters {
  final int limit;
  final int offset;
  final String? status;
  final String? category;
  final String? priority;

  const TaskFilters({
    this.limit = 10,
    this.offset = 0,
    this.status,
    this.category,
    this.priority,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilters &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset &&
          status == other.status &&
          category == other.category &&
          priority == other.priority;

  @override
  int get hashCode =>
      limit.hashCode ^
      offset.hashCode ^
      status.hashCode ^
      category.hashCode ^
      priority.hashCode;
}
