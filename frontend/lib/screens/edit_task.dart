import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/models/task_model.dart';
import 'package:frontend/riverpod/task_provider.dart';
import 'package:frontend/utils/validators.dart';

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
  final _formKey = GlobalKey<FormState>();
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

    final updateState = ref.watch(updateTaskProvider);

    // Show update API errors
    ref.listen(updateTaskProvider, (prev, next) {
      next.whenOrNull(
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_uiError(err)), backgroundColor: cs.error),
          );
        },
      );
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.horizontalPaddingForWidth(
              MediaQuery.sizeOf(context).width,
            ),
            AppSpace.lg,
            AppSpace.horizontalPaddingForWidth(
              MediaQuery.sizeOf(context).width,
            ),
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

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => Validators.requiredText(
                        v,
                        message: 'Title is required',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: AppSpace.md),

                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                      ),
                      minLines: 3,
                      maxLines: 8,
                      validator: (v) => Validators.requiredText(
                        v,
                        message: 'Description is required',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: AppSpace.md),

                    TextFormField(
                      controller: _assignedToCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assigned to (email)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.optionalEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  ],
                ),
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

  String _uiError(Object err) {
    final s = err.toString();
    return s.startsWith('Exception: ') ? s.replaceFirst('Exception: ', '') : s;
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
  }

  DateTime? _tryParseIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  String? _dueDateIsoOrNull() => _dueDate?.toUtc().toIso8601String();

  Future<void> _onSave() async {
    final cs = Theme.of(context).colorScheme;
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the highlighted fields'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    final title = _titleCtrl.text.trim();

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
