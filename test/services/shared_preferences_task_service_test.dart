import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/shared_preferences_task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadState seeds and saves the first-run state', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    final state = await service.loadState();

    expect(state.tasks, hasLength(3));
    expect(state.catalogItems, hasLength(3));
    expect(state.totalXp, 0);
    expect(state.stats.wisdom, 0);
    expect(state.potionChargeCategories, [TaskCategory.work]);
    expect(
      preferences.getString(SharedPreferencesTaskService.storageKey),
      isNotNull,
    );
  });

  test('saveState persists active, completed, and catalog tasks', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);
    final state = TaskSessionState(
      tasks: const [
        Task(
          id: 'active-task',
          title: 'Active task',
          category: TaskCategory.home,
        ),
        Task(
          id: 'completed-task',
          title: 'Completed task',
          category: TaskCategory.study,
          isCompleted: true,
        ),
      ],
      catalogItems: const [
        TaskCatalogItem(
          id: 'catalog-active-task',
          title: 'Active task',
          category: TaskCategory.home,
          sortOrder: 0,
        ),
        TaskCatalogItem(
          id: 'catalog-completed-task',
          title: 'Completed task',
          category: TaskCategory.study,
          sortOrder: 1,
          completedCount: 3,
        ),
      ],
      totalXp: 0,
      stats: const CharacterStats(
        strength: 0,
        vitality: 1,
        wisdom: 2,
        mindfulness: 0,
      ),
      potionChargeCategories: const [TaskCategory.study],
    );

    await service.saveState(state);

    final nextService = SharedPreferencesTaskService(preferences: preferences);
    final loadedState = await nextService.loadState();

    expect(loadedState.tasks.map((task) => task.id), [
      'active-task',
      'completed-task',
    ]);
    expect(loadedState.catalogItems.map((item) => item.id), [
      'catalog-active-task',
      'catalog-completed-task',
    ]);
    expect(loadedState.catalogItems.last.completedCount, 3);
    expect(loadedState.tasks.last.isCompleted, isTrue);
    expect(loadedState.stats.vitality, 1);
    expect(loadedState.stats.wisdom, 2);
    expect(loadedState.potionChargeCategories, [TaskCategory.study]);
  });

  test(
    'saveState persists total XP, stats, and ordered potion categories',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final service = SharedPreferencesTaskService(preferences: preferences);

      await service.saveState(
        TaskSessionState(
          tasks: const [],
          catalogItems: const [],
          totalXp: 95,
          stats: const CharacterStats(
            strength: 5,
            vitality: 4,
            wisdom: 3,
            mindfulness: 2,
          ),
          potionChargeCategories: const [
            TaskCategory.work,
            TaskCategory.work,
            TaskCategory.fitness,
            TaskCategory.home,
          ],
        ),
      );

      final loadedState = await service.loadState();

      expect(loadedState.totalXp, 95);
      expect(loadedState.stats.strength, 5);
      expect(loadedState.stats.mindfulness, 2);
      expect(loadedState.potionChargeCategories, [
        TaskCategory.work,
        TaskCategory.work,
        TaskCategory.fitness,
        TaskCategory.home,
      ]);
    },
  );

  test('loadState reads an existing saved JSON state', () async {
    final savedState = TaskSessionState(
      tasks: const [
        Task(
          id: 'saved-task',
          title: 'Saved task',
          category: TaskCategory.hobby,
          description: 'Already here.',
        ),
      ],
      catalogItems: const [
        TaskCatalogItem(
          id: 'catalog-saved-task',
          title: 'Saved task',
          category: TaskCategory.hobby,
          description: 'Already here.',
          sortOrder: 0,
        ),
      ],
      totalXp: 25,
      stats: const CharacterStats(
        strength: 0,
        vitality: 0,
        wisdom: 1,
        mindfulness: 4,
      ),
      potionChargeCategories: const [TaskCategory.hobby],
    );
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTaskService.storageKey: jsonEncode(savedState.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    final loadedState = await service.loadState();

    expect(loadedState.tasks.single.id, 'saved-task');
    expect(loadedState.tasks.single.category, TaskCategory.hobby);
    expect(loadedState.catalogItems.single.id, 'catalog-saved-task');
    expect(loadedState.totalXp, 25);
    expect(loadedState.stats.mindfulness, 4);
    expect(loadedState.potionChargeCategories, [TaskCategory.hobby]);
  });

  test('loadState migrates a legacy v3 key into the v4 key', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTaskService.legacyStorageKey: jsonEncode({
        'schemaVersion': 3,
        'tasks': const [],
        'catalogItems': const [],
        'totalXp': 10,
        'stats': const {
          'strength': 0,
          'vitality': 0,
          'wisdom': 0,
          'mindfulness': 0,
        },
        'potionChargeCategories': ['work'],
      }),
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    final loadedState = await service.loadState();

    expect(loadedState.totalXp, 10);
    expect(loadedState.stats.wisdom, 0);
    expect(loadedState.catalogItems, isEmpty);
    expect(
      preferences.getString(SharedPreferencesTaskService.storageKey),
      isNotNull,
    );
    expect(
      preferences.containsKey(SharedPreferencesTaskService.legacyStorageKey),
      isFalse,
    );
  });

  test('loadState migrates a legacy v2 key into the v4 key', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTaskService.olderLegacyStorageKey: jsonEncode({
        'schemaVersion': 2,
        'tasks': const [],
        'totalXp': 10,
        'stats': const {
          'strength': 0,
          'vitality': 0,
          'wisdom': 0,
          'mindfulness': 0,
        },
        'potionChargeCategories': ['work'],
      }),
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    final loadedState = await service.loadState();

    expect(loadedState.totalXp, 10);
    expect(loadedState.stats.wisdom, 0);
    expect(loadedState.catalogItems, hasLength(3));
    expect(
      preferences.getString(SharedPreferencesTaskService.storageKey),
      isNotNull,
    );
    expect(
      preferences.containsKey(
        SharedPreferencesTaskService.olderLegacyStorageKey,
      ),
      isFalse,
    );
  });

  test('loadState migrates a legacy v1 key into the v4 key', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTaskService.oldestLegacyStorageKey: jsonEncode({
        'schemaVersion': 1,
        'tasks': const [],
        'totalXp': 10,
        'potionChargeCategories': ['work'],
      }),
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    final loadedState = await service.loadState();

    expect(loadedState.totalXp, 10);
    expect(loadedState.stats.wisdom, 0);
    expect(loadedState.catalogItems, hasLength(3));
    expect(
      preferences.getString(SharedPreferencesTaskService.storageKey),
      isNotNull,
    );
    expect(
      preferences.containsKey(
        SharedPreferencesTaskService.oldestLegacyStorageKey,
      ),
      isFalse,
    );
  });

  test('loadState surfaces invalid JSON without overwriting it', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTaskService.storageKey: 'not json',
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SharedPreferencesTaskService(preferences: preferences);

    expect(service.loadState(), throwsA(isA<FormatException>()));
    expect(
      preferences.getString(SharedPreferencesTaskService.storageKey),
      'not json',
    );
  });
}
