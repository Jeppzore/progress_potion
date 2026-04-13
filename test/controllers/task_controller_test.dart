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

  test('loadTasks exposes seeded potion charge without awarding XP', () async {
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
  });

  test(
    'addTask grows the active task list without changing potion charge',
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
      expect(controller.activeTasks.first.category, TaskCategory.work);
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
