import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/models/task_model.dart';
import 'package:frontend/riverpod/task_provider.dart';

import '../widgets/dropdownfield.dart';
import 'package:frontend/widgets/due_date_field.dart';

class EditTaskSheet extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, {required TaskModel task}) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditTaskSheet(task: task),
    );
  }

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late final _titleCtrl = TextEditingController(text: widget.task.title ?? '');
  late final _descCtrl = TextEditingController(
    text: widget.task.description ?? '',
  );
  late final _assignedToCtrl = TextEditingController(
    text: widget.task.assignedTo ?? '',
  );

  late String _status = widget.task.status;
  late String _category = widget.task.category;
  late String _priority = widget.task.priority;

  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = _tryParseIso(widget.task.dueDate);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _assignedToCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppSpace.horizontalPaddingForWidth(maxWidth);

    final updateState = ref.watch(updateTaskProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpace.lg,
            horizontalPadding,
            AppSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Task',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpace.md),

              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: AppSpace.md),

              TextField(
                controller: _assignedToCtrl,
                decoration: const InputDecoration(labelText: 'Assigned to'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpace.md),

              DueDateField(
                dueDate: _dueDate,
                onPick: _pickDueDate,
                onClear: () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: AppSpace.md),

              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  AppDropdownField<String>(
                    label: 'Status',
                    value: _status,
                    items: const ['pending', 'in_progress', 'completed'],
                    onChanged: (v) => setState(() => _status = v),
                    minWidth: 170,
                  ),
                  AppDropdownField<String>(
                    label: 'Category',
                    value: _category,
                    items: const [
                      'general',
                      'technical',
                      'finance',
                      'scheduling',
                      'safety',
                    ],
                    onChanged: (v) => setState(() => _category = v),
                    minWidth: 170,
                  ),
                  AppDropdownField<String>(
                    label: 'Priority',
                    value: _priority,
                    items: const ['low', 'medium', 'high'],
                    onChanged: (v) => setState(() => _priority = v),
                    minWidth: 170,
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: updateState.isLoading ? null : _onSave,
                  icon: updateState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save changes'),
                ),
              ),

              if (updateState.hasError) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  'Error: ${updateState.error}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    // store as a date-only value (local), then convert to UTC on send
    setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
  }

  DateTime? _tryParseIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  // Backend expects a datetime string (RFC3339). Ensure we send timezone ("Z").
  String? _dueDateIsoOrNull() => _dueDate?.toUtc().toIso8601String();

  Future<void> _onSave() async {
    final cs = Theme.of(context).colorScheme;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title is required'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    await ref
        .read(updateTaskProvider.notifier)
        .updateTask(
          widget.task.id,
          title: title,
          description: _descCtrl.text.trim(),
          assignedTo: _assignedToCtrl.text.trim().isEmpty
              ? null
              : _assignedToCtrl.text.trim(),
          status: _status,
          category: _category,
          priority: _priority,
          dueDate: _dueDateIsoOrNull(), // <-- added
        );

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
