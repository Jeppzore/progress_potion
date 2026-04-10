import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/task.dart';
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
    expect(controller.currentPotionVarietyBonusXp, 5);
    expect(controller.totalXp, 0);
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
    },
  );

  test(
    'drinkPotion adds XP, consumes one full potion, and preserves overflow categories',
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

      final reward = controller.drinkPotion();

      expect(reward?.baseXp, TaskController.potionRewardXp);
      expect(reward?.varietyBonusXp, 15);
      expect(reward?.uniqueCategoryCount, 3);
      expect(reward?.totalXp, 45);
      expect(controller.totalXp, 45);
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

    final reward = controller.drinkPotion();

    expect(reward?.varietyBonusXp, 10);
    expect(reward?.totalXp, 40);
    expect(controller.totalXp, 40);
    expect(controller.potionChargeCount, 0);
  });

  test('drinkPotion does nothing when the potion is not full', () async {
    await controller.loadTasks();

    final reward = controller.drinkPotion();

    expect(reward, isNull);
    expect(controller.totalXp, 0);
    expect(controller.potionChargeCount, 1);
  });
}
