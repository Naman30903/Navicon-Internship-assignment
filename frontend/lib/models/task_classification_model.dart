import 'package:flutter/foundation.dart';

@immutable
class TaskClassification {
  final String category;
  final String priority;
  final Map<String, dynamic>? extractedEntities;
  final Map<String, dynamic>? suggestedActions;

  const TaskClassification({
    required this.category,
    required this.priority,
    this.extractedEntities,
    this.suggestedActions,
  });

  factory TaskClassification.fromJson(Map<String, dynamic> json) {
    return TaskClassification(
      category: (json['category'] as String?) ?? 'general',
      priority: (json['priority'] as String?) ?? 'low',
      extractedEntities: json['extracted_entities'] as Map<String, dynamic>?,
      suggestedActions: json['suggested_actions'] as Map<String, dynamic>?,
    );
  }
}
