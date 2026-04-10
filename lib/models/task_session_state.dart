import 'package:progress_potion/models/task.dart';

class TaskSessionState {
  TaskSessionState({
    required Iterable<Task> tasks,
    required this.totalXp,
    required Iterable<TaskCategory> potionChargeCategories,
  }) : tasks = List<Task>.unmodifiable(tasks),
       potionChargeCategories = List<TaskCategory>.unmodifiable(
         potionChargeCategories,
       );

  static const int schemaVersion = 1;

  final List<Task> tasks;
  final int totalXp;
  final List<TaskCategory> potionChargeCategories;

  TaskSessionState copyWith({
    Iterable<Task>? tasks,
    int? totalXp,
    Iterable<TaskCategory>? potionChargeCategories,
  }) {
    return TaskSessionState(
      tasks: tasks ?? this.tasks,
      totalXp: totalXp ?? this.totalXp,
      potionChargeCategories:
          potionChargeCategories ?? this.potionChargeCategories,
    );
  }

  Map<String, Object> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'tasks': [for (final task in tasks) task.toJson()],
      'totalXp': totalXp,
      'potionChargeCategories': [
        for (final category in potionChargeCategories) category.storageValue,
      ],
    };
  }

  factory TaskSessionState.fromJson(Map<String, Object?> json) {
    final schemaVersionValue = json['schemaVersion'];
    final tasksValue = json['tasks'];
    final totalXpValue = json['totalXp'];
    final potionChargeCategoriesValue = json['potionChargeCategories'];

    if (schemaVersionValue != schemaVersion) {
      throw FormatException(
        'Unsupported task session schema version: $schemaVersionValue',
      );
    }

    if (tasksValue is! List) {
      throw const FormatException('Session tasks must be a list.');
    }

    if (totalXpValue is! int || totalXpValue < 0) {
      throw const FormatException(
        'Session total XP must be a non-negative int.',
      );
    }

    if (potionChargeCategoriesValue is! List) {
      throw const FormatException(
        'Session potion charge categories must be a list.',
      );
    }

    return TaskSessionState(
      tasks: [for (final taskJson in tasksValue) _taskFromJson(taskJson)],
      totalXp: totalXpValue,
      potionChargeCategories: [
        for (final categoryJson in potionChargeCategoriesValue)
          TaskCategory.fromStorageValue(categoryJson),
      ],
    );
  }

  static Task _taskFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Session task entry must be a JSON object.');
    }

    return Task.fromJson(Map<String, Object?>.from(value));
  }
}
