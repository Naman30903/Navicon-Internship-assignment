import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/riverpod/task_provider.dart';
import 'package:frontend/widgets/dropdownfield.dart';
import 'package:frontend/widgets/due_date_field.dart';

import '../constant/padding.dart';

enum _Step { form, review }

class CreateTaskSheet extends ConsumerStatefulWidget {
  const CreateTaskSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateTaskSheet(),
    );
  }

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _assignedToCtrl = TextEditingController();

  DateTime? _dueDate;

  _Step _step = _Step.form;

  // These become editable when we receive classification
  String? _category;
  String? _priority;

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

    final classifyState = ref.watch(classifyTaskProvider);
    final createState = ref.watch(createTaskProvider); // <-- add

    // Show classify API errors
    ref.listen(classifyTaskProvider, (prev, next) {
      next.whenOrNull(
        data: (classification) {
          if (classification == null) return;
          setState(() {
            _category ??= classification.category;
            _priority ??= classification.priority;
            _step = _Step.review;
          });
        },
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_uiError(err)),
              backgroundColor: cs.error,
            ),
          );
        },
      );
    });

    // Show create API errors
    ref.listen(createTaskProvider, (prev, next) {
      next.whenOrNull(
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_uiError(err)),
              backgroundColor: cs.error,
            ),
          );
        },
      );
    });

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _step == _Step.form
                ? _buildForm(context, classifyState, cs)
                : _buildReview(context, createState, cs), // <-- pass createState
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue<dynamic> classifyState,
    ColorScheme cs,
  ) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Task',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title *'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpace.md),

        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: 'Description *'),
          minLines: 3,
          maxLines: 8,
        ),
        const SizedBox(height: AppSpace.md),

        TextField(
          controller: _assignedToCtrl,
          decoration: const InputDecoration(labelText: 'Assigned to (email)'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpace.md),

        DueDateField(
          dueDate: _dueDate,
          onPick: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setState(() => _dueDate = picked);
          },
          onClear: () => setState(() => _dueDate = null),
        ),

        const SizedBox(height: AppSpace.xl),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: classifyState.isLoading ? null : _onClassifyPressed,
            icon: classifyState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              classifyState.isLoading
                  ? 'Classifying…'
                  : 'Next: Review classification',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(
    BuildContext context,
    AsyncValue<dynamic> createState, // <-- change from classifyState to createState
    ColorScheme cs,
  ) {
    final theme = Theme.of(context);
    final classification = ref.read(classifyTaskProvider).value;

    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                ref.read(classifyTaskProvider.notifier).reset();
                setState(() => _step = _Step.form);
              },
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            Expanded(
              child: Text(
                'Review',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),

        if (classification == null) ...[
          Text(
            'No classification available.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.lg),
        ] else ...[
          Text(
            'Auto-generated',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _KeyValueRow(label: 'Category', value: classification.category),
          _KeyValueRow(label: 'Priority', value: classification.priority),

          const SizedBox(height: AppSpace.lg),
          Text(
            'Override (optional)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              AppDropdownField<String>(
                label: 'Category',
                value: _category ?? classification.category,
                items: const [
                  'general',
                  'technical',
                  'finance',
                  'scheduling',
                  'safety',
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              AppDropdownField<String>(
                label: 'Priority',
                value: _priority ?? classification.priority,
                items: const ['low', 'medium', 'high'],
                onChanged: (v) => setState(() => _priority = v),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpace.xl),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: createState.isLoading ? null : _onSavePressed, // <-- disable while saving
            icon: createState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(createState.isLoading ? 'Saving…' : 'Save task'),
          ),
        ),
      ],
    );
  }

  Future<void> _onClassifyPressed() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title and Description are required'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    await ref.read(classifyTaskProvider.notifier).classify(description: desc);
  }

  Future<void> _onSavePressed() async {
    final cs = Theme.of(context).colorScheme;

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final assignedTo = _assignedToCtrl.text.trim();
    final dueDateIso = _dueDate?.toUtc().toIso8601String();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title and Description are required'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    // Save with override values (if any)
    await ref
        .read(createTaskProvider.notifier)
        .createTask(
          title: title,
          description: desc,
          category: _category,
          priority: _priority,
          assignedTo: assignedTo.isEmpty ? null : assignedTo,
          dueDate: dueDateIso,
        );

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  String _uiError(Object err) {
    final s = err.toString();
    return s.startsWith('Exception: ') ? s.replaceFirst('Exception: ', '') : s;
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
