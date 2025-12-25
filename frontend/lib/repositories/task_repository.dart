import 'package:dio/dio.dart';
import 'package:frontend/models/task_classification_model.dart';
import '../api/api_client.dart';
import '../models/task_history.dart';
import '../models/task_model.dart';
import '../models/pagination_model.dart';

class TaskRepository {
  final ApiClient _apiClient;

  TaskRepository(this._apiClient);

  /// Fetch tasks with optional filters
  Future<TaskListResponse> fetchTasks({
    int limit = 10,
    int offset = 0,
    String? status,
    String? category,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
      };

      final response = await _apiClient.get(
        '/tasks',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final tasks = data.map((json) => TaskModel.fromJson(json)).toList();
        final pagination = PaginationModel.fromJson(
          response.data['pagination'],
        );

        return TaskListResponse(tasks: tasks, pagination: pagination);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch tasks');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a single task by ID
  Future<TaskModel> getTaskById(String id) async {
    try {
      final response = await _apiClient.get('/tasks/$id');

      if (response.data['success'] == true) {
        return TaskModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Task not found');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new task
  Future<TaskModel> createTask({
    String? title,
    String? description,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
  }) async {
    try {
      final taskData = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate,
      };

      final response = await _apiClient.dio.post('/tasks', data: taskData);

      if (response.data['success'] == true) {
        return TaskModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create task');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update an existing task
  Future<TaskModel> updateTask(
    String id, {
    String? title,
    String? description,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate,
      };

      final response = await _apiClient.dio.patch('/tasks/$id', data: updates);

      if (response.data['success'] == true) {
        return TaskModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update task');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    try {
      final response = await _apiClient.delete('/tasks/$id');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete task');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Classify a task based on its description
  Future<TaskClassification> classifyTask({required String description}) async {
    final response = await _apiClient.post(
      '/tasks/classify',
      data: {'description': description},
    );

    if (response.data['success'] == true) {
      return TaskClassification.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception(response.data['error'] ?? 'Failed to classify task');
  }

  /// Get task history
  Future<List<TaskHistory>> getTaskHistory(String taskId) async {
    try {
      final response = await _apiClient.get('/tasks/$taskId/history');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch task history',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timed out. Please check your internet and try again.',
        );

      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please try again.');

      case DioExceptionType.cancel:
        return Exception('Request was cancelled. Please try again.');

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final backendMessage = _extractBackendMessage(error.response?.data);

        if (status == 400) {
          return Exception(
            backendMessage ??
                'Some details look incorrect. Please review and try again.',
          );
        }
        if (status == 401) {
          return Exception('Your session has expired. Please log in again.');
        }
        if (status == 403) {
          return Exception('You don’t have permission to do that.');
        }
        if (status == 404) {
          return Exception('We couldn’t find what you were looking for.');
        }
        if (status != null && status >= 500) {
          return Exception(
            'We’re having trouble on our side. Please try again shortly.',
          );
        }

        return Exception(
          backendMessage ?? 'Something went wrong. Please try again.',
        );

      default:
        return Exception('Something went wrong. Please try again.');
    }
  }

  String? _extractBackendMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final s = data.trim();
      return s.isEmpty ? null : s;
    }

    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message.trim();

      final error = data['error']?.toString();
      if (error != null && error.trim().isNotEmpty) return error.trim();

      // Validation errors: { errors: [{ message: "...", path: [...] }, ...] }
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final m = first['message']?.toString();
          if (m != null && m.trim().isNotEmpty) return m.trim();
        }
      }
    }

    return null;
  }
}

class TaskListResponse {
  final List<TaskModel> tasks;
  final PaginationModel pagination;

  TaskListResponse({required this.tasks, required this.pagination});
}
