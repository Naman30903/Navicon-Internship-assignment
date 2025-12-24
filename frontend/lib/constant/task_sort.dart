enum TaskSort { newestFirst, oldestFirst, dueDate }

extension TaskSortLabel on TaskSort {
  String get label => switch (this) {
    TaskSort.newestFirst => 'Newest first',
    TaskSort.oldestFirst => 'Oldest first',
    TaskSort.dueDate => 'Due date',
  };
}
