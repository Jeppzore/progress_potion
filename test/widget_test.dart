import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/services/shared_preferences_task_service.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:progress_potion/widgets/potion_reward_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the hero with potion, avatar, and visible stats', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('ProgressPotion'), findsOneWidget);
    expect(find.text('Brew your next level'), findsOneWidget);
    expect(find.text('Potionkeeper'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Vitality'), findsOneWidget);
    expect(find.text('Wisdom'), findsOneWidget);
    expect(find.text('Mindfulness'), findsOneWidget);
    expect(find.text('1 of 3 charges'), findsOneWidget);
    expect(find.text('Drink Potion'), findsNothing);

    await _scrollToText(tester, 'Active Tasks');
    expect(find.text('Active Tasks'), findsOneWidget);
  });

  testWidgets('active complete button uses the warm action color', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _scrollToText(tester, 'Active Tasks');

    final completeFinder = find.widgetWithText(FilledButton, 'Complete').first;
    final button = tester.widget<FilledButton>(completeFinder);
    final context = tester.element(completeFinder);
    final backgroundColor = button.style?.backgroundColor?.resolve({});

    expect(backgroundColor, Theme.of(context).colorScheme.secondary);
  });

  testWidgets('adds a task from the add task screen', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Add task'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task title'),
      'Write release summary',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Keep the update crisp.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(homeScreen.taskController.totalCount, 4);
    expect(
      homeScreen.taskController.activeTasks.first.title,
      'Write release summary',
    );
    expect(
      homeScreen.taskController.activeTasks.first.category,
      TaskCategory.study,
    );
  });

  testWidgets('persists a task added from the UI after app rebuild', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await _pumpApp(
      tester,
      taskService: SharedPreferencesTaskService(preferences: preferences),
    );

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task title'),
      'Persist widget task',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpApp(
      tester,
      taskService: SharedPreferencesTaskService(preferences: preferences),
    );

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(
      homeScreen.taskController.activeTasks.first.title,
      'Persist widget task',
    );
    expect(
      homeScreen.taskController.activeTasks.first.category,
      TaskCategory.home,
    );
  });

  testWidgets(
    'completing tasks fills the potion without awarding XP immediately',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(homeScreen.taskController.totalXp, 0);

      await _completeVisibleTask(tester);

      expect(homeScreen.taskController.completedCount, 2);
      expect(homeScreen.taskController.potionChargeCount, 2);
      expect(homeScreen.taskController.totalXp, 0);
      expect(homeScreen.taskController.stats.strength, 0);
      expect(
        homeScreen.taskController.completedTasks.any(
          (task) => task.title == 'Refill water flask',
        ),
        isTrue,
      );
    },
  );

  testWidgets('drinking a full potion updates the visible stat cards', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    await _completeVisibleTask(tester);
    await _completeVisibleTask(tester);

    expect(homeScreen.taskController.canDrinkPotion, isTrue);
    expect(homeScreen.taskController.totalXp, 0);

    await homeScreen.taskController.drinkPotion();
    await tester.pumpAndSettle();

    expect(homeScreen.taskController.totalXp, 45);
    expect(homeScreen.taskController.stats.strength, 1);
    expect(homeScreen.taskController.stats.wisdom, 1);
    expect(homeScreen.taskController.stats.mindfulness, 1);
    expect(homeScreen.taskController.potionChargeCount, 0);
    expect(find.text('Drink Potion'), findsNothing);
  });

  testWidgets('reward dialog renders XP and explicit stat gains', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return PotionRewardDialog(
              reward: const PotionRewardResult(
                baseXp: 30,
                varietyBonusXp: 15,
                uniqueCategoryCount: 3,
                statGains: CharacterStats(
                  strength: 1,
                  vitality: 0,
                  wisdom: 1,
                  mindfulness: 1,
                ),
              ),
              totalXp: 45,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rewards Collected'), findsOneWidget);
    expect(find.text('+45 XP'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Wisdom'), findsOneWidget);
    expect(find.text('Mindfulness'), findsOneWidget);
    expect(find.text('Total XP now: 45'), findsOneWidget);
  });

  testWidgets('shows empty state in controller terms when all tasks are done', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    while (homeScreen.taskController.activeTasks.isNotEmpty) {
      await _completeVisibleTask(tester);
    }

    expect(homeScreen.taskController.activeTasks, isEmpty);
    expect(homeScreen.taskController.potionChargeCount, 3);
    expect(homeScreen.taskController.totalXp, 0);
  });
}

Future<void> _pumpApp(WidgetTester tester, {TaskService? taskService}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: ProgressPotionApp(taskService: taskService),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeVisibleTask(WidgetTester tester) async {
  final completeButton = find.widgetWithText(FilledButton, 'Complete');
  await tester.scrollUntilVisible(
    completeButton,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(completeButton.first);
  await tester.pumpAndSettle();
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
