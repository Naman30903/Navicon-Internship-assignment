import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';
import '../constant/task_sort.dart';
import '../models/filter.dart';

class SearchFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final FilterState filters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<FilterState> onFiltersChanged;
  final VoidCallback onClearAll;

  const SearchFiltersBar({
    super.key,
    required this.searchController,
    required this.filters,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search title or description…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChipMenu<String?>(
                label: 'Status',
                value: filters.status,
                items: const [null, 'pending', 'in_progress', 'completed'],
                itemLabel: (v) => v == null
                    ? 'Any'
                    : (v == 'in_progress'
                          ? 'In Progress'
                          : '${v[0].toUpperCase()}${v.substring(1)}'),
                onSelected: (v) => onFiltersChanged(
                  FilterState(
                    status: v,
                    category: filters.category,
                    priority: filters.priority,
                    sort: filters.sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<String?>(
                label: 'Category',
                value: filters.category,
                items: const [
                  null,
                  'general',
                  'technical',
                  'finance',
                  'scheduling',
                  'safety',
                ],
                itemLabel: (v) => v ?? 'Any',
                onSelected: (v) => onFiltersChanged(
                  FilterState(
                    status: filters.status,
                    category: v,
                    priority: filters.priority,
                    sort: filters.sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<String?>(
                label: 'Priority',
                value: filters.priority,
                items: const [null, 'low', 'medium', 'high'],
                itemLabel: (v) => v ?? 'Any',
                onSelected: (v) => onFiltersChanged(
                  FilterState(
                    status: filters.status,
                    category: filters.category,
                    priority: v,
                    sort: filters.sort,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _ChipMenu<TaskSort>(
                label: 'Sort',
                value: filters.sort,
                items: const [
                  TaskSort.newestFirst,
                  TaskSort.oldestFirst,
                  TaskSort.dueDate,
                ],
                itemLabel: (v) => v.label,
                onSelected: (v) => onFiltersChanged(
                  FilterState(
                    status: filters.status,
                    category: filters.category,
                    priority: filters.priority,
                    sort: v,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(Icons.filter_alt_off, color: cs.primary),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipMenu<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  const _ChipMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = itemLabel(value);

    return MenuAnchor(
      builder: (context, controller, child) {
        return ActionChip(
          label: Text('$label: $current'),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          labelStyle: theme.textTheme.labelLarge,
        );
      },
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: () => onSelected(item),
            child: Text(itemLabel(item)),
          ),
      ],
    );
  }
}
