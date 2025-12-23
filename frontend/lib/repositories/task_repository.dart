import 'package:dio/dio.dart';
import 'package:frontend/models/task_classification_model.dart';
import '../api/api_client.dart';
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

      final response = await _apiClient.post('/tasks', data: taskData);

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
  }) async {
    try {
      final updates = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
      };

      final response = await _apiClient.put('/tasks/$id', data: updates);

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

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        return Exception(
          error.response?.data['error'] ??
              'Server error: ${error.response?.statusCode}',
        );
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      default:
        return Exception('An unexpected error occurred: ${error.message}');
    }
  }
}

class TaskListResponse {
  final List<TaskModel> tasks;
  final PaginationModel pagination;

  TaskListResponse({required this.tasks, required this.pagination});
}
