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

class TaskCatalogItem {
  const TaskCatalogItem({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.isFavorite = false,
    this.isDefault = false,
    this.sortOrder = 0,
    this.completedCount = 0,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final String description;
  final bool isFavorite;
  final bool isDefault;
  final int sortOrder;
  final int completedCount;

  TaskCatalogItem copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    String? description,
    bool? isFavorite,
    bool? isDefault,
    int? sortOrder,
    int? completedCount,
  }) {
    return TaskCatalogItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  Task toTask({String? id, bool isCompleted = false}) {
    return Task(
      id: id ?? this.id,
      title: title,
      category: category,
      description: description,
      isCompleted: isCompleted,
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.storageValue,
      'isFavorite': isFavorite,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'completedCount': completedCount,
    };
  }

  factory TaskCatalogItem.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final isFavorite = json['isFavorite'];
    final isDefault = json['isDefault'];
    final sortOrder = json['sortOrder'] ?? json['createdAt'] ?? 0;
    final completedCount = json['completedCount'] ?? 0;

    if (id is! String || id.isEmpty) {
      throw const FormatException(
        'Catalog item id must be a non-empty string.',
      );
    }

    if (title is! String || title.isEmpty) {
      throw const FormatException(
        'Catalog item title must be a non-empty string.',
      );
    }

    if (description is! String) {
      throw const FormatException('Catalog item description must be a string.');
    }

    if (isFavorite is! bool) {
      throw const FormatException('Catalog item favorite flag must be bool.');
    }

    if (isDefault is! bool) {
      throw const FormatException('Catalog item default flag must be bool.');
    }

    if (sortOrder is! int || sortOrder < 0) {
      throw const FormatException(
        'Catalog item sort order must be a non-negative int.',
      );
    }

    if (completedCount is! int || completedCount < 0) {
      throw const FormatException(
        'Catalog item completed count must be a non-negative int.',
      );
    }

    return TaskCatalogItem(
      id: id,
      title: title,
      category: TaskCategory.fromStorageValue(json['category']),
      description: description,
      isFavorite: isFavorite,
      isDefault: isDefault,
      sortOrder: sortOrder,
      completedCount: completedCount,
    );
  }

  factory TaskCatalogItem.fromTask(
    Task task, {
    String? id,
    bool isFavorite = false,
    bool isDefault = false,
    int sortOrder = 0,
    int completedCount = 0,
  }) {
    return TaskCatalogItem(
      id: id ?? 'catalog-${task.id}',
      title: task.title,
      category: task.category,
      description: task.description,
      isFavorite: isFavorite,
      isDefault: isDefault,
      sortOrder: sortOrder,
      completedCount: completedCount,
    );
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
