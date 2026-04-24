import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';

const List<Task> defaultSeedTasks = [
  Task(
    id: 'brew-morning-focus',
    title: 'Brew morning focus',
    category: TaskCategory.work,
    description: 'Choose the one win that matters most before opening chat.',
    isCompleted: true,
  ),
  Task(
    id: 'refill-water-flask',
    title: 'Refill water flask',
    category: TaskCategory.fitness,
    description:
        'Set yourself up for the next work block with one small reset.',
  ),
  Task(
    id: 'ship-one-tiny-step',
    title: 'Ship one tiny step',
    category: TaskCategory.hobby,
    description:
        'Finish something concrete, even if it only takes ten minutes.',
  ),
];

const List<TaskCatalogItem> defaultSeedCatalogItems = [
  TaskCatalogItem(
    id: 'catalog-brew-morning-focus',
    title: 'Brew morning focus',
    category: TaskCategory.work,
    description: 'Choose the one win that matters most before opening chat.',
    isStarter: true,
    isDefault: true,
    sortOrder: 0,
    completedCount: 1,
  ),
  TaskCatalogItem(
    id: 'catalog-refill-water-flask',
    title: 'Refill water flask',
    category: TaskCategory.fitness,
    description:
        'Set yourself up for the next work block with one small reset.',
    isStarter: true,
    isDefault: true,
    sortOrder: 1,
  ),
  TaskCatalogItem(
    id: 'catalog-ship-one-tiny-step',
    title: 'Ship one tiny step',
    category: TaskCategory.hobby,
    description:
        'Finish something concrete, even if it only takes ten minutes.',
    isStarter: true,
    isDefault: true,
    sortOrder: 2,
  ),
];

const Set<String> defaultSeedTaskIds = {
  'brew-morning-focus',
  'refill-water-flask',
  'ship-one-tiny-step',
};

class TaskSessionState {
  TaskSessionState({
    required Iterable<Task> tasks,
    required Iterable<TaskCatalogItem> catalogItems,
    required this.totalXp,
    required this.stats,
    required Iterable<TaskCategory> potionChargeCategories,
  }) : tasks = List<Task>.unmodifiable(tasks),
       catalogItems = List<TaskCatalogItem>.unmodifiable(catalogItems),
       potionChargeCategories = List<TaskCategory>.unmodifiable(
         potionChargeCategories,
       );

  static const int schemaVersion = 5;

  final List<Task> tasks;
  final List<TaskCatalogItem> catalogItems;
  final int totalXp;
  final CharacterStats stats;
  final List<TaskCategory> potionChargeCategories;

  TaskSessionState copyWith({
    Iterable<Task>? tasks,
    Iterable<TaskCatalogItem>? catalogItems,
    int? totalXp,
    CharacterStats? stats,
    Iterable<TaskCategory>? potionChargeCategories,
  }) {
    return TaskSessionState(
      tasks: tasks ?? this.tasks,
      catalogItems: catalogItems ?? this.catalogItems,
      totalXp: totalXp ?? this.totalXp,
      stats: stats ?? this.stats,
      potionChargeCategories:
          potionChargeCategories ?? this.potionChargeCategories,
    );
  }

  Map<String, Object> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'tasks': [for (final task in tasks) task.toJson()],
      'catalogItems': [for (final item in catalogItems) item.toJson()],
      'totalXp': totalXp,
      'stats': stats.toJson(),
      'potionChargeCategories': [
        for (final category in potionChargeCategories) category.storageValue,
      ],
    };
  }

  factory TaskSessionState.fromJson(Map<String, Object?> json) {
    final schemaVersionValue = json['schemaVersion'];
    final tasksValue = json['tasks'];
    final catalogItemsValue = json['catalogItems'];
    final totalXpValue = json['totalXp'];
    final statsValue = json['stats'];
    final potionChargeCategoriesValue = json['potionChargeCategories'];

    if (schemaVersionValue != 1 &&
        schemaVersionValue != 2 &&
        schemaVersionValue != 3 &&
        schemaVersionValue != 4 &&
        schemaVersionValue != schemaVersion) {
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

    final tasks = [for (final taskJson in tasksValue) _taskFromJson(taskJson)];
    final catalogItems = _catalogItemsFromJson(catalogItemsValue, tasks);

    return TaskSessionState(
      tasks: tasks,
      catalogItems: catalogItems,
      totalXp: totalXpValue,
      stats: schemaVersionValue == 1
          ? CharacterStats.zero
          : _statsFromJson(statsValue),
      potionChargeCategories: [
        for (final categoryJson in potionChargeCategoriesValue)
          TaskCategory.fromStorageValue(categoryJson),
      ],
    );
  }

  static List<TaskCatalogItem> _catalogItemsFromJson(
    Object? value,
    List<Task> tasks,
  ) {
    if (value == null) {
      final catalogItems = <TaskCatalogItem>[...defaultSeedCatalogItems];
      final existingIds = <String>{for (final item in catalogItems) item.id};
      var nextSortOrder = catalogItems.fold<int>(
        -1,
        (current, item) => item.sortOrder > current ? item.sortOrder : current,
      );

      for (final task in tasks) {
        final isDefault = defaultSeedTaskIds.contains(task.id);
        final candidate = TaskCatalogItem.fromTask(
          task,
          isDefault: isDefault,
          sortOrder: ++nextSortOrder,
        );
        final alreadyExists = catalogItems.any(
          (item) =>
              item.id == candidate.id ||
              (item.title == candidate.title &&
                  item.category == candidate.category &&
                  item.description == candidate.description),
        );
        if (alreadyExists) {
          continue;
        }

        final uniqueId = _uniqueCatalogItemId(candidate.id, existingIds);
        existingIds.add(uniqueId);
        catalogItems.add(candidate.copyWith(id: uniqueId));
      }

      return catalogItems;
    }

    if (value is! List) {
      throw const FormatException('Session catalog items must be a list.');
    }

    return [for (final itemJson in value) _catalogItemFromJson(itemJson)];
  }

  static TaskCatalogItem _catalogItemFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Session catalog item entry must be a JSON object.',
      );
    }

    return TaskCatalogItem.fromJson(Map<String, Object?>.from(value));
  }

  static Task _taskFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Session task entry must be a JSON object.');
    }

    return Task.fromJson(Map<String, Object?>.from(value));
  }

  static CharacterStats _statsFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Session stats must be a JSON object.');
    }

    return CharacterStats.fromJson(Map<String, Object?>.from(value));
  }

  static String _uniqueCatalogItemId(String baseId, Set<String> existingIds) {
    if (!existingIds.contains(baseId)) {
      return baseId;
    }

    var suffix = 2;
    while (existingIds.contains('$baseId-$suffix')) {
      suffix += 1;
    }
    return '$baseId-$suffix';
  }
}
