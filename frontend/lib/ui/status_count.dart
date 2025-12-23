import 'package:frontend/models/task_model.dart';

class StatusCounts {
  final int pending;
  final int inProgress;
  final int completed;

  const StatusCounts({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  factory StatusCounts.fromTasks(List<TaskModel> tasks) {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (final t in tasks) {
      switch (t.status) {
        case 'completed':
          completed++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'pending':
        default:
          pending++;
          break;
      }
    }

    return StatusCounts(
      pending: pending,
      inProgress: inProgress,
      completed: completed,
    );
  }
}
