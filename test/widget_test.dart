import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/screens/home/home_screen.dart';

void main() {
  testWidgets('renders the home loop with potion progress and tasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProgressPotionApp());
    await tester.pumpAndSettle();

    expect(find.text('ProgressPotion'), findsOneWidget);
    expect(find.text('Potion progress'), findsOneWidget);
    expect(find.text('Active Tasks'), findsOneWidget);
    expect(find.text('1 of 3 charges filled'), findsOneWidget);
    expect(find.text('Total XP: 0'), findsOneWidget);
    expect(
      find.text('Variety bonus so far: +5 XP from 1 category'),
      findsOneWidget,
    );
    expect(find.text('Drink Potion'), findsNothing);
  });

  testWidgets('adds a task from the add task screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProgressPotionApp());
    await tester.pumpAndSettle();

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

    expect(find.text('Write release summary'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);

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

  testWidgets(
    'completing tasks fills the potion without awarding XP immediately',
    (WidgetTester tester) async {
      await tester.pumpWidget(ProgressPotionApp());
      await tester.pumpAndSettle();

      final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(homeScreen.taskController.totalXp, 0);

      await _completeVisibleTask(tester);

      expect(homeScreen.taskController.completedCount, 2);
      expect(homeScreen.taskController.potionChargeCount, 2);
      expect(homeScreen.taskController.totalXp, 0);
      expect(
        homeScreen.taskController.completedTasks.any(
          (task) => task.title == 'Refill water flask',
        ),
        isTrue,
      );
    },
  );

  testWidgets('drinking a full potion shows a reward popup and updates XP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProgressPotionApp());
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    await _completeVisibleTask(tester);
    await _completeVisibleTask(tester);

    expect(homeScreen.taskController.canDrinkPotion, isTrue);
    expect(homeScreen.taskController.totalXp, 0);

    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('Drink Potion'), findsOneWidget);
    await tester.ensureVisible(find.text('Drink Potion'));
    await tester.tap(find.text('Drink Potion'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Potion claimed'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Base reward: +30 XP'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Variety bonus: +15 XP (3 categories)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Total gained: +45 XP'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Total XP: 45'),
      ),
      findsOneWidget,
    );
    expect(homeScreen.taskController.totalXp, 45);
    expect(homeScreen.taskController.potionChargeCount, 0);

    await tester.tap(find.text('Nice'));
    await tester.pumpAndSettle();

    expect(find.text('Drink Potion'), findsNothing);
  });

  testWidgets('rapid repeat drink taps only claim one potion reward', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProgressPotionApp());
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    final controller = homeScreen.taskController;

    await controller.addTask(
      title: 'Overflow charge one',
      category: TaskCategory.study,
    );
    await controller.addTask(
      title: 'Overflow charge two',
      category: TaskCategory.home,
    );
    await controller.addTask(
      title: 'Overflow charge three',
      category: TaskCategory.fitness,
    );
    final activeTaskIds = controller.activeTasks
        .map((task) => task.id)
        .toList();
    for (final taskId in activeTaskIds) {
      await controller.completeTask(taskId);
    }
    await tester.pumpAndSettle();

    expect(controller.potionChargeCount, 6);
    expect(controller.canDrinkPotion, isTrue);

    await tester.ensureVisible(find.text('Drink Potion'));
    await tester.tap(find.text('Drink Potion'));
    await tester.tap(find.text('Drink Potion'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Potion claimed'), findsOneWidget);
    expect(controller.totalXp, 45);
    expect(controller.potionChargeCount, 3);

    await tester.tap(find.text('Nice'));
    await tester.pumpAndSettle();

    expect(find.text('Drink Potion'), findsOneWidget);
  });

  testWidgets('shows empty state when all active tasks are completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProgressPotionApp());
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    while (find
        .widgetWithText(FilledButton, 'Complete')
        .evaluate()
        .isNotEmpty) {
      await _completeVisibleTask(tester);
    }

    expect(homeScreen.taskController.activeTasks, isEmpty);
    expect(homeScreen.taskController.potionChargeCount, 3);
    expect(homeScreen.taskController.totalXp, 0);

    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('No active tasks'), findsOneWidget);
  });
}

Future<void> _completeVisibleTask(WidgetTester tester) async {
  final completeButton = find.widgetWithText(FilledButton, 'Complete').first;
  await tester.scrollUntilVisible(
    completeButton,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(completeButton);
  await tester.pumpAndSettle();
}
