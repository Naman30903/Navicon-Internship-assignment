import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';

/// Reusable due date picker used across create/edit sheets.
class DueDateField extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const DueDateField({
    super.key,
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final label = dueDate == null
        ? 'Pick due date'
        : '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today),
            label: Text(label),
          ),
        ),
        if (dueDate != null) ...[
          const SizedBox(width: AppSpace.md),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear date',
          ),
        ],
      ],
    );
  }
}
