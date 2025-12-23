import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/riverpod/task_provider.dart';

import '../constant/padding.dart';

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

  String _priority = 'low';
  String _category = 'general';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = AppSpace.horizontalPaddingForWidth(maxWidth);

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
                'Create Task',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Fix production bug',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more context…',
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  _DropdownField<String>(
                    label: 'Priority',
                    value: _priority,
                    items: const ['low', 'medium', 'high'],
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                  _DropdownField<String>(
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
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final title = _titleCtrl.text.trim();
                    final description = _descCtrl.text.trim();

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
                        .read(createTaskProvider.notifier)
                        .createTask(
                          title: title,
                          description: description.isEmpty ? null : description,
                          priority: _priority,
                          category: _category,
                        );

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
