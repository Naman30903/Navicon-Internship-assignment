import 'package:flutter/foundation.dart';

@immutable
class TaskModel {
  final String id;
  final String? title;
  final String? description;
  final String status;
  final String category;
  final String priority;
  final String? assignedTo;
  final String? dueDate;

  final Map<String, dynamic>? extractedEntities;
  final Map<String, dynamic>? suggestedActions;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    this.title,
    this.description,
    required this.status,
    required this.category,
    required this.priority,
    this.assignedTo,
    this.dueDate,
    this.extractedEntities,
    this.suggestedActions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'low',
      assignedTo: json['assigned_to'] as String?,
      dueDate: json['due_date'] as String?,
      extractedEntities: json['extracted_entities'] as Map<String, dynamic>?,
      suggestedActions: json['suggested_actions'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'status': status,
      'category': category,
      'priority': priority,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (dueDate != null) 'due_date': dueDate,
      if (extractedEntities != null) 'extracted_entities': extractedEntities,
      if (suggestedActions != null) 'suggested_actions': suggestedActions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
    Map<String, dynamic>? extractedEntities,
    Map<String, dynamic>? suggestedActions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      extractedEntities: extractedEntities ?? this.extractedEntities,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaskModel(id: $id, title: $title, status: $status)';
}
