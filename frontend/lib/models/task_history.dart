import 'package:flutter/material.dart';

@immutable
class TaskHistory {
  final String id;
  final String taskId;
  final String action;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String changedBy;
  final DateTime changedAt;

  const TaskHistory({
    required this.id,
    required this.taskId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.changedBy,
    required this.changedAt,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      action: json['action'] as String,
      oldValue: json['old_value'] as Map<String, dynamic>?,
      newValue: json['new_value'] as Map<String, dynamic>?,
      changedBy: json['changed_by'] as String? ?? 'system',
      changedAt: DateTime.parse(json['changed_at'] as String),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'status_changed':
        return 'Status Changed';
      case 'completed':
        return 'Completed';
      default:
        return action;
    }
  }

  IconData get actionIcon {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'updated':
        return Icons.edit_outlined;
      case 'status_changed':
        return Icons.swap_horiz;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.history;
    }
  }
}
