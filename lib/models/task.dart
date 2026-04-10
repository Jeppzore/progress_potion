enum TaskCategory {
  fitness('Fitness'),
  study('Study'),
  work('Work'),
  hobby('Hobby'),
  home('Home');

  const TaskCategory(this.displayName);

  final String displayName;

  String get storageValue => name;

  static TaskCategory fromStorageValue(Object? value) {
    if (value is! String) {
      throw const FormatException('Task category must be a string.');
    }

    for (final category in TaskCategory.values) {
      if (category.storageValue == value) {
        return category;
      }
    }

    throw FormatException('Unknown task category: $value');
  }
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

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.storageValue,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final isCompleted = json['isCompleted'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Task id must be a non-empty string.');
    }

    if (title is! String || title.isEmpty) {
      throw const FormatException('Task title must be a non-empty string.');
    }

    if (description is! String) {
      throw const FormatException('Task description must be a string.');
    }

    if (isCompleted is! bool) {
      throw const FormatException('Task completion must be a boolean.');
    }

    return Task(
      id: id,
      title: title,
      description: description,
      category: TaskCategory.fromStorageValue(json['category']),
      isCompleted: isCompleted,
    );
  }
}
