import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';

void main() {
  late TaskController controller;

  setUp(() {
    controller = TaskController(taskService: InMemoryTaskService());
  });

  test('loadTasks exposes seeded potion charge and catalog', () async {
    await controller.loadTasks();

    expect(controller.totalCount, 3);
    expect(controller.completedCount, 1);
    expect(controller.potionChargeCount, 1);
    expect(controller.potionChargeCategories, [TaskCategory.work]);
    expect(controller.currentPotionCategories, [TaskCategory.work]);
    expect(controller.currentPotionVarietyBonusXp, 5);
    expect(controller.totalXp, 0);
    expect(controller.stats.strength, 0);
    expect(controller.potionProgress, closeTo(1 / 3, 0.0001));
    expect(controller.catalogItems, hasLength(3));
    expect(
      controller.getCatalogByCategory(TaskCategory.work).single.isDefault,
      isTrue,
    );
  });

  test(
    'addTask remains a compatibility helper that also seeds the catalog',
    () async {
      await controller.loadTasks();

      await controller.addTask(
        title: 'Draft release notes',
        category: TaskCategory.work,
        description: 'Keep the summary short and clear.',
      );

      expect(controller.totalCount, 4);
      expect(controller.potionChargeCount, 1);
      expect(
        controller.activeTasks.any(
          (task) => task.title == 'Draft release notes',
        ),
        isTrue,
      );
      expect(
        controller.catalogItems.any(
          (item) => item.title == 'Draft release notes',
        ),
        isTrue,
      );
    },
  );

  test(
    'createCatalogItem stores a task in the catalog without activating it',
    () async {
      await controller.loadTasks();

      await controller.createCatalogItem(
        title: 'Plan weekly review',
        category: TaskCategory.study,
        description: 'Keep it lightweight.',
      );

      expect(controller.totalCount, 3);
      expect(controller.activeTasks, hasLength(2));
      expect(controller.catalogItems, hasLength(4));
      expect(
        controller
            .getCatalogByCategory(TaskCategory.study)
            .any((item) => item.title == 'Plan weekly review'),
        isTrue,
      );
    },
  );

  test('createCatalogItem rejects blank titles before persisting', () async {
    await controller.loadTasks();

    expect(
      () => controller.createCatalogItem(
        title: '   ',
        category: TaskCategory.study,
      ),
      throwsArgumentError,
    );
    expect(controller.catalogItems, hasLength(3));
  });

  test('toggleFavorite pins favorites to the top of a category list', () async {
    await controller.loadTasks();

    final first = await controller.createCatalogItem(
      title: 'Study warmup',
      category: TaskCategory.study,
    );
    final second = await controller.createCatalogItem(
      title: 'Study deep dive',
      category: TaskCategory.study,
    );

    await controller.toggleFavorite(second.id);

    final studyItems = controller.getCatalogByCategory(TaskCategory.study);
    expect(studyItems.first.id, second.id);
    expect(studyItems.first.isFavorite, isTrue);
    expect(studyItems.any((item) => item.id == first.id), isTrue);
  });

  test(
    'favoriteCatalogItems sorts favorites by most used by default',
    () async {
      final seededController = TaskController(
        taskService: InMemoryTaskService(
          initialState: TaskSessionState(
            tasks: const [],
            catalogItems: const [
              TaskCatalogItem(
                id: 'catalog-low',
                title: 'Low use',
                category: TaskCategory.work,
                isFavorite: true,
                sortOrder: 4,
                completedCount: 2,
              ),
              TaskCatalogItem(
                id: 'catalog-high',
                title: 'High use',
                category: TaskCategory.work,
                isFavorite: true,
                sortOrder: 1,
                completedCount: 5,
              ),
              TaskCatalogItem(
                id: 'catalog-hidden',
                title: 'Hidden',
                category: TaskCategory.work,
                sortOrder: 8,
                completedCount: 9,
              ),
            ],
            totalXp: 0,
            stats: CharacterStats.zero,
            potionChargeCategories: const [],
          ),
        ),
      );
      await seededController.loadTasks();

      expect(seededController.favoriteCatalogItems().map((item) => item.id), [
        'catalog-high',
        'catalog-low',
      ]);
      expect(
        seededController
            .favoriteCatalogItems(sort: FavoriteSort.libraryOrder)
            .map((item) => item.id),
        ['catalog-low', 'catalog-high'],
      );
    },
  );

  test(
    'activateCatalogItem snapshots catalog data into the active list',
    () async {
      await controller.loadTasks();

      final created = await controller.createCatalogItem(
        title: 'Stretch break',
        category: TaskCategory.fitness,
        description: 'Get up and move.',
      );

      await controller.activateCatalogItem(created.id);

      expect(controller.totalCount, 4);
      expect(controller.activeTasks.first.title, 'Stretch break');
      expect(controller.activeTasks.first.category, TaskCategory.fitness);
      expect(
        controller.catalogItems.any((item) => item.id == created.id),
        isTrue,
      );
    },
  );

  test('removeActiveTask removes only uncompleted tasks', () async {
    await controller.loadTasks();

    final created = await controller.createCatalogItem(
      title: 'Clear inbox',
      category: TaskCategory.work,
    );
    await controller.activateCatalogItem(created.id);

    expect(controller.totalCount, 4);

    await controller.removeActiveTask(controller.activeTasks.first.id);

    expect(controller.totalCount, 3);
    expect(
      controller.activeTasks.any((task) => task.id == created.id),
      isFalse,
    );
    expect(controller.completedCount, 1);
  });

  test(
    'deleteUserCatalogItem removes a user-created task from future browsing',
    () async {
      await controller.loadTasks();

      final created = await controller.createCatalogItem(
        title: 'Write retro notes',
        category: TaskCategory.home,
      );
      await controller.activateCatalogItem(created.id);

      await controller.deleteUserCatalogItem(created.id);

      expect(
        controller.catalogItems.any((item) => item.id == created.id),
        isFalse,
      );
      expect(
        controller.activeTasks.any((task) => task.title == 'Write retro notes'),
        isTrue,
      );
    },
  );

  test(
    'catalog ids stay unique when a fallback suffix is already taken',
    () async {
      final seededController = TaskController(
        taskService: InMemoryTaskService(
          initialState: TaskSessionState(
            tasks: const [],
            catalogItems: const [
              TaskCatalogItem(
                id: 'catalog-reset-inbox',
                title: 'Reset inbox',
                category: TaskCategory.work,
                sortOrder: 0,
              ),
              TaskCatalogItem(
                id: 'catalog-reset-inbox-4',
                title: 'Reset inbox',
                category: TaskCategory.work,
                description: 'Existing suffix',
                sortOrder: 1,
              ),
            ],
            totalXp: 0,
            stats: CharacterStats.zero,
            potionChargeCategories: const [],
          ),
        ),
      );
      await seededController.loadTasks();

      final created = await seededController.createCatalogItem(
        title: 'Reset inbox',
        category: TaskCategory.work,
        description: 'Fresh start',
      );

      expect(
        created.id,
        isNot(anyOf('catalog-reset-inbox', 'catalog-reset-inbox-4')),
      );
      expect(created.id.startsWith('catalog-reset-inbox-'), isTrue);
      expect(
        seededController.catalogItems.where((item) => item.id == created.id),
        hasLength(1),
      );
    },
  );

  test('completeTask fills the potion and ignores repeat completion', () async {
    await controller.loadTasks();

    await controller.completeTask('refill-water-flask');
    await controller.completeTask('refill-water-flask');
    await controller.completeTask('ship-one-tiny-step');

    expect(controller.completedCount, 3);
    expect(controller.potionChargeCount, 3);
    expect(controller.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.fitness,
      TaskCategory.hobby,
    ]);
    expect(controller.currentPotionUniqueCategoryCount, 3);
    expect(controller.currentPotionVarietyBonusXp, 15);
    expect(controller.potionProgress, 1);
    expect(controller.canDrinkPotion, isTrue);
    expect(controller.totalXp, 0);
    expect(controller.stats.mindfulness, 0);
    expect(
      controller.catalogItems
          .singleWhere((item) => item.id == 'catalog-refill-water-flask')
          .completedCount,
      1,
    );
    expect(
      controller.catalogItems
          .singleWhere((item) => item.id == 'catalog-ship-one-tiny-step')
          .completedCount,
      1,
    );
  });

  test(
    'completeTask ignores concurrent completion for the same task',
    () async {
      await controller.loadTasks();

      final firstCompletion = controller.completeTask('refill-water-flask');
      final secondCompletion = controller.completeTask('refill-water-flask');
      await Future.wait([firstCompletion, secondCompletion]);

      expect(controller.completedCount, 2);
      expect(controller.potionChargeCount, 2);
      expect(controller.potionChargeCategories, [
        TaskCategory.work,
        TaskCategory.fitness,
      ]);
      expect(controller.totalXp, 0);
      expect(controller.stats.strength, 0);
      expect(
        controller.catalogItems
            .singleWhere((item) => item.id == 'catalog-refill-water-flask')
            .completedCount,
        1,
      );
    },
  );

  test('markTaskAsFavorite reuses an existing catalog item', () async {
    await controller.loadTasks();

    await controller.markTaskAsFavorite('refill-water-flask');

    final item = controller.catalogItems.singleWhere(
      (item) => item.id == 'catalog-refill-water-flask',
    );
    expect(item.isFavorite, isTrue);
    expect(controller.isTaskFavorite('refill-water-flask'), isTrue);
    expect(
      controller.catalogItems.where(
        (item) => item.title == 'Refill water flask',
      ),
      hasLength(1),
    );
  });

  test(
    'markTaskAsFavorite creates a favorite for an active-only task',
    () async {
      final seededController = TaskController(
        taskService: InMemoryTaskService(
          initialState: TaskSessionState(
            tasks: const [
              Task(
                id: 'active-only',
                title: 'Active only',
                category: TaskCategory.home,
                description: 'Not saved yet.',
              ),
            ],
            catalogItems: const [],
            totalXp: 0,
            stats: CharacterStats.zero,
            potionChargeCategories: const [],
          ),
        ),
      );
      await seededController.loadTasks();

      await seededController.markTaskAsFavorite('active-only');

      expect(seededController.catalogItems, hasLength(1));
      expect(seededController.catalogItems.single.title, 'Active only');
      expect(seededController.catalogItems.single.isFavorite, isTrue);
      expect(seededController.isTaskFavorite('active-only'), isTrue);
    },
  );

  test(
    'drinkPotion adds XP, grants stat gains, and preserves overflow categories',
    () async {
      await controller.loadTasks();

      await controller.addTask(
        title: 'Extra charge one',
        category: TaskCategory.study,
      );
      await controller.addTask(
        title: 'Extra charge two',
        category: TaskCategory.home,
      );
      await controller.completeTask('refill-water-flask');
      await controller.completeTask('ship-one-tiny-step');
      await controller.completeTask('extra-charge-one');
      await controller.completeTask('extra-charge-two');

      expect(controller.potionChargeCount, 5);
      expect(controller.canDrinkPotion, isTrue);
      expect(controller.currentPotionUniqueCategoryCount, 3);
      expect(controller.currentPotionVarietyBonusXp, 15);

      final reward = await controller.drinkPotion();

      expect(reward?.baseXp, TaskController.potionRewardXp);
      expect(reward?.varietyBonusXp, 15);
      expect(reward?.uniqueCategoryCount, 3);
      expect(reward?.totalXp, 45);
      expect(reward?.statGains.strength, 1);
      expect(reward?.statGains.wisdom, 1);
      expect(reward?.statGains.mindfulness, 1);
      expect(reward?.statGains.vitality, 0);
      expect(controller.totalXp, 45);
      expect(controller.stats.strength, 1);
      expect(controller.stats.wisdom, 1);
      expect(controller.stats.mindfulness, 1);
      expect(controller.stats.vitality, 0);
      expect(controller.potionChargeCount, 2);
      expect(controller.potionChargeCategories, [
        TaskCategory.study,
        TaskCategory.home,
      ]);
      expect(controller.currentPotionUniqueCategoryCount, 2);
      expect(controller.currentPotionVarietyBonusXp, 10);
      expect(controller.potionProgress, closeTo(2 / 3, 0.0001));
      expect(controller.canDrinkPotion, isFalse);
    },
  );

  test('drinkPotion awards variety bonus once per unique category', () async {
    await controller.loadTasks();

    await controller.addTask(
      title: 'Duplicate work charge',
      category: TaskCategory.work,
    );
    await controller.completeTask('duplicate-work-charge');
    await controller.completeTask('refill-water-flask');

    expect(controller.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.work,
      TaskCategory.fitness,
    ]);
    expect(controller.currentPotionUniqueCategoryCount, 2);
    expect(controller.currentPotionVarietyBonusXp, 10);

    final reward = await controller.drinkPotion();

    expect(reward?.varietyBonusXp, 10);
    expect(reward?.totalXp, 40);
    expect(reward?.statGains.wisdom, 2);
    expect(reward?.statGains.strength, 1);
    expect(controller.totalXp, 40);
    expect(controller.stats.wisdom, 2);
    expect(controller.stats.strength, 1);
    expect(controller.potionChargeCount, 0);
  });

  test('drinkPotion does nothing when the potion is not full', () async {
    await controller.loadTasks();

    final reward = await controller.drinkPotion();

    expect(reward, isNull);
    expect(controller.totalXp, 0);
    expect(controller.stats, CharacterStats.zero);
    expect(controller.potionChargeCount, 1);
  });

  test('addTask persists through a new controller instance', () async {
    final service = InMemoryTaskService();
    final firstController = TaskController(taskService: service);
    await firstController.loadTasks();

    await firstController.addTask(
      title: 'Persist this task',
      category: TaskCategory.home,
      description: 'It should survive the next controller.',
    );

    final secondController = TaskController(taskService: service);
    await secondController.loadTasks();

    expect(secondController.totalCount, 4);
    expect(secondController.activeTasks.first.title, 'Persist this task');
    expect(secondController.activeTasks.first.category, TaskCategory.home);
    expect(
      secondController.catalogItems.any(
        (item) => item.title == 'Persist this task',
      ),
      isTrue,
    );
  });

  test('completeTask persists completion and potion charge queue', () async {
    final service = InMemoryTaskService();
    final firstController = TaskController(taskService: service);
    await firstController.loadTasks();

    await firstController.completeTask('refill-water-flask');

    final secondController = TaskController(taskService: service);
    await secondController.loadTasks();

    expect(secondController.completedCount, 2);
    expect(secondController.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.fitness,
    ]);
    expect(secondController.stats.strength, 0);
  });

  test('drinkPotion persists XP, stats, and overflow categories', () async {
    final service = InMemoryTaskService(
      initialState: TaskSessionState(
        tasks: [
          const Task(
            id: 'one',
            title: 'One',
            category: TaskCategory.work,
            isCompleted: true,
          ),
          const Task(
            id: 'two',
            title: 'Two',
            category: TaskCategory.study,
            isCompleted: true,
          ),
          const Task(
            id: 'three',
            title: 'Three',
            category: TaskCategory.home,
            isCompleted: true,
          ),
          const Task(
            id: 'four',
            title: 'Four',
            category: TaskCategory.fitness,
            isCompleted: true,
          ),
        ],
        catalogItems: const [
          TaskCatalogItem(
            id: 'catalog-one',
            title: 'One',
            category: TaskCategory.work,
            sortOrder: 0,
          ),
          TaskCatalogItem(
            id: 'catalog-two',
            title: 'Two',
            category: TaskCategory.study,
            sortOrder: 1,
          ),
          TaskCatalogItem(
            id: 'catalog-three',
            title: 'Three',
            category: TaskCategory.home,
            sortOrder: 2,
          ),
          TaskCatalogItem(
            id: 'catalog-four',
            title: 'Four',
            category: TaskCategory.fitness,
            sortOrder: 3,
          ),
        ],
        totalXp: 5,
        stats: const CharacterStats(
          strength: 1,
          vitality: 0,
          wisdom: 2,
          mindfulness: 0,
        ),
        potionChargeCategories: [
          TaskCategory.work,
          TaskCategory.study,
          TaskCategory.home,
          TaskCategory.fitness,
        ],
      ),
    );
    final firstController = TaskController(taskService: service);
    await firstController.loadTasks();

    final reward = await firstController.drinkPotion();

    expect(reward?.totalXp, 45);
    expect(reward?.statGains.wisdom, 2);
    expect(reward?.statGains.vitality, 1);

    final secondController = TaskController(taskService: service);
    await secondController.loadTasks();

    expect(secondController.totalXp, 50);
    expect(secondController.stats.strength, 1);
    expect(secondController.stats.vitality, 1);
    expect(secondController.stats.wisdom, 4);
    expect(secondController.potionChargeCategories, [TaskCategory.fitness]);
  });
}
