enum TaskCategory {
  fitness('Fitness'),
  study('Study'),
  work('Work'),
  hobby('Hobby'),
  home('Home');

  const TaskCategory(this.displayName);

  final String displayName;
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final String description;
  final bool isCompleted;

  Task copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    String? description,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
