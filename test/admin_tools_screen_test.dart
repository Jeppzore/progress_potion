import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/models/default_task_session_state.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/services/shared_preferences_task_service.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens admin tools from the hidden debug long press', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, taskService: _ImmediateTaskService());

    expect(find.text('Admin Tools'), findsNothing);

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Admin Tools'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-grant-xp-button')), findsOneWidget);
  });

  testWidgets('invalid admin inputs are rejected without mutating progress', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, taskService: _ImmediateTaskService());

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(
      find.byType(HomeScreen, skipOffstage: false),
    );

    await tester.enterText(find.byKey(const ValueKey('admin-xp-input')), '-5');
    await tester.ensureVisible(
      find.byKey(const ValueKey('admin-grant-xp-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-grant-xp-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive whole number for XP.'), findsOneWidget);
    expect(homeScreen.taskController.totalXp, 0);

    await tester.enterText(
      find.byKey(const ValueKey('admin-strength-input')),
      'abc',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('admin-grant-stats-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-grant-stats-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Use whole numbers for stats. Leave a field blank for zero.'),
      findsOneWidget,
    );
    expect(homeScreen.taskController.stats.strength, 0);
  });

  testWidgets('admin stat grant accepts blank fields as zero', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, taskService: _ImmediateTaskService());

    final homeScreen = tester.widget<HomeScreen>(
      find.byType(HomeScreen, skipOffstage: false),
    );

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-strength-input')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-strength-input')),
      '7',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('admin-grant-stats-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-grant-stats-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Stats updated:'), findsOneWidget);
    expect(homeScreen.taskController.stats.strength, 7);
    expect(homeScreen.taskController.stats.vitality, 0);
    expect(homeScreen.taskController.stats.wisdom, 0);
    expect(homeScreen.taskController.stats.mindfulness, 0);
  });

  testWidgets('admin tools wait for the initial load before opening', (
    WidgetTester tester,
  ) async {
    final taskService = _DelayedLoadTaskService();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ProgressPotionApp(taskService: taskService),
      ),
    );
    await tester.pump();

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pump();

    expect(find.text('Admin Tools'), findsNothing);

    taskService.completeLoad();
    await tester.pumpAndSettle();

    expect(find.text('Admin Tools'), findsOneWidget);
  });

  testWidgets('submit buttons disable while an admin save is in flight', (
    WidgetTester tester,
  ) async {
    final taskService = _DelayedSaveTaskService();
    await _pumpApp(tester, taskService: taskService);

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('admin-xp-input')), '12');
    await tester.ensureVisible(
      find.byKey(const ValueKey('admin-grant-xp-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-grant-xp-button')));
    await tester.pump();

    expect(find.text('Applying...'), findsOneWidget);

    taskService.completeSave();
    await tester.pumpAndSettle();

    final homeScreen = tester.widget<HomeScreen>(
      find.byType(HomeScreen, skipOffstage: false),
    );
    expect(homeScreen.taskController.totalXp, 12);
  });

  testWidgets('admin potion charge and reset flow update shared state', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, taskService: _ImmediateTaskService());

    final homeScreen = tester.widget<HomeScreen>(
      find.byType(HomeScreen, skipOffstage: false),
    );

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-add-charge-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-add-charge-button')));
    await tester.pumpAndSettle();

    expect(homeScreen.taskController.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.work,
    ]);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-reset-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-reset-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset progress'));
    await tester.pumpAndSettle();

    final seedState = createDefaultTaskSessionState();
    expect(homeScreen.taskController.totalXp, seedState.totalXp);
    expect(homeScreen.taskController.stats, seedState.stats);
    expect(
      homeScreen.taskController.potionChargeCategories,
      seedState.potionChargeCategories,
    );
  });

  testWidgets('admin XP changes persist through shared preferences restart', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await _pumpApp(
      tester,
      taskService: SharedPreferencesTaskService(preferences: preferences),
    );

    await tester.longPress(find.byKey(const ValueKey('admin-tools-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('admin-xp-input')), '14');
    await tester.ensureVisible(
      find.byKey(const ValueKey('admin-grant-xp-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-grant-xp-button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpApp(
      tester,
      taskService: SharedPreferencesTaskService(preferences: preferences),
    );

    final homeScreen = tester.widget<HomeScreen>(
      find.byType(HomeScreen, skipOffstage: false),
    );
    expect(homeScreen.taskController.totalXp, 14);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required TaskService taskService,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: ProgressPotionApp(taskService: taskService),
    ),
  );
  await tester.pumpAndSettle();
}

class _ImmediateTaskService implements TaskService {
  _ImmediateTaskService({TaskSessionState? initialState})
    : _state = initialState ?? createDefaultTaskSessionState();

  TaskSessionState _state;

  @override
  Future<TaskSessionState> loadState() async => _state;

  @override
  Future<void> saveState(TaskSessionState state) async {
    _state = state;
  }
}

class _DelayedSaveTaskService extends _ImmediateTaskService {
  Completer<void>? _saveCompleter;

  @override
  Future<void> saveState(TaskSessionState state) async {
    _saveCompleter = Completer<void>();
    await _saveCompleter!.future;
    await super.saveState(state);
  }

  void completeSave() {
    _saveCompleter?.complete();
  }
}

class _DelayedLoadTaskService extends _ImmediateTaskService {
  final Completer<TaskSessionState> _loadCompleter =
      Completer<TaskSessionState>();

  @override
  Future<TaskSessionState> loadState() => _loadCompleter.future;

  void completeLoad() {
    if (!_loadCompleter.isCompleted) {
      _loadCompleter.complete(createDefaultTaskSessionState());
    }
  }
}
