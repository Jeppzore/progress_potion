import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';

void main() {
  test('Task round trips through JSON', () {
    const task = Task(
      id: 'study-session',
      title: 'Study session',
      category: TaskCategory.study,
      description: 'Read one chapter.',
      isCompleted: true,
    );

    final decoded = Task.fromJson(task.toJson());

    expect(decoded.id, task.id);
    expect(decoded.title, task.title);
    expect(decoded.category, task.category);
    expect(decoded.description, task.description);
    expect(decoded.isCompleted, task.isCompleted);
  });

  test('TaskCatalogItem round trips through JSON', () {
    const catalogItem = TaskCatalogItem(
      id: 'catalog-study-session',
      title: 'Study session',
      category: TaskCategory.study,
      description: 'Read one chapter.',
      isFavorite: true,
      isStarter: true,
      isDefault: false,
      sortOrder: 7,
      completedCount: 4,
    );

    final decoded = TaskCatalogItem.fromJson(catalogItem.toJson());

    expect(decoded.id, catalogItem.id);
    expect(decoded.title, catalogItem.title);
    expect(decoded.category, catalogItem.category);
    expect(decoded.description, catalogItem.description);
    expect(decoded.isFavorite, isTrue);
    expect(decoded.isStarter, isTrue);
    expect(decoded.isDefault, isFalse);
    expect(decoded.sortOrder, 7);
    expect(decoded.completedCount, 4);
  });

  test('TaskSessionState round trips through JSON', () {
    final state = TaskSessionState(
      tasks: const [
        Task(
          id: 'work-task',
          title: 'Work task',
          category: TaskCategory.work,
          isCompleted: true,
        ),
        Task(id: 'home-task', title: 'Home task', category: TaskCategory.home),
      ],
      catalogItems: const [
        TaskCatalogItem(
          id: 'catalog-work-task',
          title: 'Work task',
          category: TaskCategory.work,
          isStarter: true,
          sortOrder: 0,
          completedCount: 2,
        ),
        TaskCatalogItem(
          id: 'catalog-home-task',
          title: 'Home task',
          category: TaskCategory.home,
          sortOrder: 1,
        ),
      ],
      totalXp: 85,
      stats: const CharacterStats(
        strength: 2,
        vitality: 4,
        wisdom: 6,
        mindfulness: 8,
      ),
      potionChargeCategories: const [TaskCategory.work, TaskCategory.home],
    );

    final decoded = TaskSessionState.fromJson(state.toJson());

    expect(decoded.tasks.map((task) => task.id), ['work-task', 'home-task']);
    expect(decoded.catalogItems.map((item) => item.id), [
      'catalog-work-task',
      'catalog-home-task',
    ]);
    expect(decoded.catalogItems.first.isStarter, isTrue);
    expect(decoded.catalogItems.last.isStarter, isFalse);
    expect(decoded.catalogItems.first.completedCount, 2);
    expect(decoded.totalXp, 85);
    expect(decoded.stats.strength, 2);
    expect(decoded.stats.mindfulness, 8);
    expect(decoded.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.home,
    ]);
  });

  test(
    'TaskSessionState migrates schema v2 sessions without catalog items',
    () {
      final decoded = TaskSessionState.fromJson({
        'schemaVersion': 2,
        'tasks': [
          {
            'id': 'legacy-task',
            'title': 'Legacy task',
            'description': '',
            'category': 'work',
            'isCompleted': true,
          },
        ],
        'totalXp': 30,
        'stats': const {
          'strength': 1,
          'vitality': 2,
          'wisdom': 3,
          'mindfulness': 4,
        },
        'potionChargeCategories': ['work'],
      });

      expect(decoded.totalXp, 30);
      expect(decoded.stats.strength, 1);
      expect(decoded.catalogItems, hasLength(4));
      expect(
        decoded.catalogItems.any((item) => item.id == 'catalog-legacy-task'),
        isTrue,
      );
      expect(
        decoded.catalogItems.where((item) => item.isDefault),
        hasLength(3),
      );
      expect(
        decoded.catalogItems.every((item) => item.completedCount >= 0),
        isTrue,
      );
    },
  );

  test('TaskSessionState migrates schema v3 catalog counts to zero', () {
    final decoded = TaskSessionState.fromJson({
      'schemaVersion': 3,
      'tasks': const [],
      'catalogItems': [
        {
          'id': 'catalog-v3-task',
          'title': 'V3 task',
          'description': '',
          'category': 'study',
          'isFavorite': true,
          'isDefault': false,
          'sortOrder': 0,
        },
      ],
      'totalXp': 0,
      'stats': const {
        'strength': 0,
        'vitality': 0,
        'wisdom': 0,
        'mindfulness': 0,
      },
      'potionChargeCategories': const <String>[],
    });

    expect(decoded.catalogItems.single.completedCount, 0);
    expect(decoded.catalogItems.single.isFavorite, isTrue);
    expect(decoded.catalogItems.single.isStarter, isFalse);
  });

  test('TaskCatalogItem defaults starter state from legacy default items', () {
    final decoded = TaskCatalogItem.fromJson({
      'id': 'catalog-built-in',
      'title': 'Built in',
      'description': '',
      'category': 'work',
      'isFavorite': false,
      'isDefault': true,
      'sortOrder': 0,
    });

    expect(decoded.isDefault, isTrue);
    expect(decoded.isStarter, isTrue);
  });

  test('TaskSessionState migrates schema v1 sessions with zeroed stats', () {
    final decoded = TaskSessionState.fromJson({
      'schemaVersion': 1,
      'tasks': [
        {
          'id': 'legacy-task',
          'title': 'Legacy task',
          'description': '',
          'category': 'work',
          'isCompleted': true,
        },
      ],
      'totalXp': 30,
      'potionChargeCategories': ['work'],
    });

    expect(decoded.totalXp, 30);
    expect(decoded.stats.strength, 0);
    expect(decoded.stats.vitality, 0);
    expect(decoded.stats.wisdom, 0);
    expect(decoded.stats.mindfulness, 0);
    expect(decoded.catalogItems, hasLength(4));
    expect(
      decoded.catalogItems.any((item) => item.id == 'catalog-legacy-task'),
      isTrue,
    );
  });

  test('TaskCategory rejects unknown storage values', () {
    expect(
      () => TaskCategory.fromStorageValue('wellness'),
      throwsA(isA<FormatException>()),
    );
  });

  test('TaskSessionState rejects non-object task entries', () {
    expect(
      () => TaskSessionState.fromJson({
        'schemaVersion': TaskSessionState.schemaVersion,
        'tasks': ['not a task'],
        'catalogItems': const [],
        'totalXp': 0,
        'stats': const {
          'strength': 0,
          'vitality': 0,
          'wisdom': 0,
          'mindfulness': 0,
        },
        'potionChargeCategories': <String>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('TaskSessionState rejects missing stats for schema v3', () {
    expect(
      () => TaskSessionState.fromJson({
        'schemaVersion': TaskSessionState.schemaVersion,
        'tasks': const [],
        'catalogItems': const [],
        'totalXp': 0,
        'potionChargeCategories': const <String>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
