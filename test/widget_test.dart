import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/services/shared_preferences_task_service.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:progress_potion/widgets/character_avatar.dart';
import 'package:progress_potion/widgets/potion_progress_card.dart';
import 'package:progress_potion/widgets/potion_reward_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the hero with potion view by default', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('ProgressPotion'), findsOneWidget);
    expect(find.text('Brew your next level'), findsOneWidget);
    expect(find.text('Potionkeeper'), findsNothing);
    expect(find.text('1 of 3 charges'), findsOneWidget);
    expect(find.text('Drink Potion'), findsNothing);

    await _scrollToText(tester, 'Active Tasks');
    expect(find.text('Active Tasks'), findsOneWidget);
  });

  testWidgets(
    'swiping the hero reveals the character while keeping tasks below',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await tester.drag(
        find.byKey(const ValueKey('hero-page-view')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Potionkeeper'), findsOneWidget);
      expect(find.text('Brew your next level'), findsNothing);

      await _scrollToText(tester, 'Active Tasks');
      expect(find.text('Active Tasks'), findsOneWidget);
    },
  );

  testWidgets('hero page toggles update their selected styling', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final potionToggle = find.byKey(
      const ValueKey('hero-page-toggle-pill-Potion'),
    );
    final characterToggle = find.byKey(
      const ValueKey('hero-page-toggle-pill-Character'),
    );
    final context = tester.element(potionToggle);
    final selectedColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.14);
    final unselectedColor = Colors.white.withValues(alpha: 0.55);

    expect(_toggleColor(tester, potionToggle), selectedColor);
    expect(_toggleColor(tester, characterToggle), unselectedColor);

    await tester.ensureVisible(find.text('Character'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Character'));
    await tester.pumpAndSettle();

    expect(_toggleColor(tester, potionToggle), unselectedColor);
    expect(_toggleColor(tester, characterToggle), selectedColor);
  });

  testWidgets(
    'character page grows to fit wrapped stat cards on narrow screens',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 1400),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.4),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  PotionProgressCard(
                    xp: 2500000,
                    stats: const CharacterStats(
                      strength: 1200000,
                      vitality: 2300000,
                      wisdom: 3400000,
                      mindfulness: 4500000,
                    ),
                    progress: 0.33,
                    potionChargeCount: 1,
                    potionCapacity: TaskController.potionCapacity,
                    currentPotionCategories: const [TaskCategory.fitness],
                    baseRewardXp: TaskController.potionRewardXp,
                    varietyBonusXp: 10,
                    varietyCategoryCount: 1,
                    canDrinkPotion: false,
                    isDrinkingPotion: false,
                    celebrationCount: 0,
                    onDrinkPotion: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heroViewFinder = find.byKey(const ValueKey('hero-page-view'));
      final potionHeight = tester.getSize(heroViewFinder).height;

      await tester.ensureVisible(find.text('Character'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Character'));
      await tester.pumpAndSettle();

      final characterHeight = tester.getSize(heroViewFinder).height;

      expect(characterHeight, greaterThan(potionHeight));
      expect(find.text('1.2M'), findsOneWidget);
      expect(find.text('4.5M'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping an incomplete potion jiggles it without drinking', (
    WidgetTester tester,
  ) async {
    var drinkCount = 0;

    await _pumpPotionCard(
      tester,
      potionChargeCount: 1,
      currentPotionCategories: const [TaskCategory.fitness],
      onDrinkPotion: () {
        drinkCount += 1;
      },
    );

    expect(
      find.byKey(const ValueKey('potion-bottle-jiggle-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('potion-bottle-tap-target')));
    await tester.pump();

    expect(drinkCount, 0);
    expect(
      find.byKey(const ValueKey('potion-bottle-jiggle-1')),
      findsOneWidget,
    );
  });

  testWidgets('drink button still uses the existing callback when full', (
    WidgetTester tester,
  ) async {
    var drinkCount = 0;

    await _pumpPotionCard(
      tester,
      progress: 1,
      potionChargeCount: TaskController.potionCapacity,
      currentPotionCategories: const [
        TaskCategory.fitness,
        TaskCategory.study,
        TaskCategory.hobby,
      ],
      canDrinkPotion: true,
      onDrinkPotion: () {
        drinkCount += 1;
      },
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Drink Potion'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Drink Potion'));
    await tester.pump();

    expect(drinkCount, 1);
  });

  testWidgets(
    'active complete button stays subtle by default and turns green on interaction',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await _scrollToText(tester, 'Active Tasks');

      final completeFinder = find
          .widgetWithText(FilledButton, 'Complete')
          .first;
      final button = tester.widget<FilledButton>(completeFinder);
      final context = tester.element(completeFinder);
      final backgroundColor = button.style?.backgroundColor?.resolve({});
      final hoveredColor = button.style?.backgroundColor?.resolve({
        WidgetState.hovered,
      });
      final pressedColor = button.style?.backgroundColor?.resolve({
        WidgetState.pressed,
      });

      expect(
        backgroundColor,
        Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
      );
      expect(hoveredColor, const Color(0xFF3C9A5F).withValues(alpha: 0.92));
      expect(pressedColor, const Color(0xFF3C9A5F));
    },
  );

  testWidgets(
    'potion liquid shows blended layers for multiple queued categories',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await _completeVisibleTask(tester);
      await _completeVisibleTask(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pumpAndSettle();

      final liquidBaseFinder = find.byKey(const ValueKey('potion-liquid-base'));

      expect(liquidBaseFinder, findsOneWidget);
      expect(find.byKey(const ValueKey('potion-band-wisdom')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('potion-band-strength')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('potion-band-mindfulness')),
        findsOneWidget,
      );

      final liquidBase = tester.widget<DecoratedBox>(liquidBaseFinder);
      final gradient =
          (liquidBase.decoration as BoxDecoration).gradient! as LinearGradient;
      final mixedMidColor = gradient.colors[1];

      expect(_channelValue(mixedMidColor, 16), greaterThan(80));
      expect(_channelValue(mixedMidColor, 8), greaterThan(80));
      expect(_channelValue(mixedMidColor, 0), greaterThan(80));
    },
  );

  testWidgets(
    'character avatar keeps beard below the mouth and brows below the hairline',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CharacterAvatar(
                  stats: CharacterStats.zero,
                  celebrationCount: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final baseTorsoSize = tester.getSize(
        find.byKey(const ValueKey('avatar-torso')),
      );
      final baseMouthSize = tester.getSize(
        find.byKey(const ValueKey('avatar-mouth')),
      );
      expect(find.byKey(const ValueKey('avatar-beard')), findsNothing);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CharacterAvatar(
                  stats: CharacterStats(
                    strength: 6,
                    vitality: 40,
                    wisdom: 6,
                    mindfulness: 6,
                  ),
                  celebrationCount: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grownTorsoSize = tester.getSize(
        find.byKey(const ValueKey('avatar-torso')),
      );
      final grownMouthSize = tester.getSize(
        find.byKey(const ValueKey('avatar-mouth')),
      );
      final mouthRect = tester.getRect(
        find.byKey(const ValueKey('avatar-mouth')),
      );
      final beardRect = tester.getRect(
        find.byKey(const ValueKey('avatar-beard')),
      );
      final hairRect = tester.getRect(
        find.byKey(const ValueKey('avatar-hairline')),
      );
      final leftBrowRect = tester.getRect(
        find.byKey(const ValueKey('avatar-left-brow')),
      );
      final rightBrowRect = tester.getRect(
        find.byKey(const ValueKey('avatar-right-brow')),
      );

      expect(find.byKey(const ValueKey('avatar-beard')), findsOneWidget);
      expect(grownTorsoSize.width, greaterThan(baseTorsoSize.width));
      expect(grownTorsoSize.height, greaterThan(baseTorsoSize.height));
      expect(grownMouthSize.width, greaterThan(baseMouthSize.width));
      expect(grownMouthSize.height, greaterThan(baseMouthSize.height));
      expect(beardRect.top, greaterThanOrEqualTo(mouthRect.bottom));
      expect(leftBrowRect.top, greaterThan(hairRect.bottom));
      expect(rightBrowRect.top, greaterThan(hairRect.bottom));
    },
  );

  testWidgets(
    'vitality posture rises to standing at 100 and plateaus after that',
    (WidgetTester tester) async {
      Future<Rect> torsoRectForVitality(int vitality) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CharacterAvatar(
                    stats: CharacterStats(
                      strength: 0,
                      vitality: vitality,
                      wisdom: 0,
                      mindfulness: 0,
                    ),
                    celebrationCount: 0,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.byKey(const ValueKey('avatar-torso')));
      }

      final seatedTorso = await torsoRectForVitality(0);
      expect(find.byKey(const ValueKey('avatar-seat')), findsOneWidget);

      final standingTorso = await torsoRectForVitality(100);
      expect(find.byKey(const ValueKey('avatar-seat')), findsNothing);

      final plateauTorso = await torsoRectForVitality(1000);

      expect(standingTorso.top, lessThan(seatedTorso.top));
      expect((standingTorso.top - plateauTorso.top).abs(), lessThan(0.01));
      expect(
        (standingTorso.height - plateauTorso.height).abs(),
        lessThan(0.01),
      );
    },
  );

  testWidgets('character tap triggers sparkle feedback', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _CharacterAvatarHarness(
        onAvatarTap: () {
          tapCount += 1;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.byKey(const ValueKey('avatar-sparkle-0')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tapCount, 1);
    expect(find.byKey(const ValueKey('avatar-sparkle-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-sparkle-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-sparkle-2')), findsOneWidget);
  });

  testWidgets(
    'reduced motion keeps character tappable without nonessential animation',
    (WidgetTester tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _CharacterAvatarHarness(
          disableAnimations: true,
          onAvatarTap: () {
            tapCount += 1;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(tapCount, 1);
      expect(
        find.byKey(const ValueKey('avatar-reduced-motion-pulse')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('avatar-sparkle-0')), findsNothing);
      expect(find.byKey(const ValueKey('avatar-sparkle-1')), findsNothing);
      expect(find.byKey(const ValueKey('avatar-sparkle-2')), findsNothing);
      await tester.pump(const Duration(milliseconds: 220));
    },
  );

  testWidgets('character avatar exposes button semantics when tappable', (
    WidgetTester tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      const _CharacterAvatarHarness(disableAnimations: true),
    );
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('avatar-tap-target')),
    );

    final data = semantics.getSemanticsData();

    expect(data.label, 'Potionkeeper companion');
    expect(data.hint, 'Tap to encourage your companion');
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    semanticsHandle.dispose();
  });

  testWidgets(
    'character page wires avatar tap feedback through the hero view',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await tester.ensureVisible(find.text('Character'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Character'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('avatar-tap-target')),
        -120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap for a wave'), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-tap-target')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(const ValueKey('avatar-reduced-motion-pulse')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 220));
    },
  );

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
      expect(find.text('Done'), findsNWidgets(2));
      expect(find.text('Reward stored in the potion'), findsNWidgets(2));
      expect(
        homeScreen.taskController.completedTasks.any(
          (task) => task.title == 'Refill water flask',
        ),
        isTrue,
      );
    },
  );

  testWidgets('tapping a full potion bottle drinks it and updates the hero', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    await _completeVisibleTask(tester);
    await _completeVisibleTask(tester);

    expect(homeScreen.taskController.canDrinkPotion, isTrue);
    expect(homeScreen.taskController.totalXp, 0);

    await _scrollToTopView(tester);
    await tester.tap(find.byKey(const ValueKey('potion-bottle-tap-target')));
    await tester.pumpAndSettle();

    expect(find.text('Rewards Collected'), findsOneWidget);
    expect(homeScreen.taskController.totalXp, 45);
    expect(homeScreen.taskController.stats.strength, 1);
    expect(homeScreen.taskController.stats.wisdom, 1);
    expect(homeScreen.taskController.stats.mindfulness, 1);
    expect(homeScreen.taskController.potionChargeCount, 0);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Continue'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Character'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Character'));
    await tester.pumpAndSettle();

    expect(find.text('Potionkeeper'), findsOneWidget);
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

Future<void> _pumpPotionCard(
  WidgetTester tester, {
  double progress = 0.33,
  int potionChargeCount = 1,
  List<TaskCategory> currentPotionCategories = const [TaskCategory.fitness],
  bool canDrinkPotion = false,
  CharacterStats stats = CharacterStats.zero,
  VoidCallback? onDrinkPotion,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              PotionProgressCard(
                xp: 12,
                stats: stats,
                progress: progress,
                potionChargeCount: potionChargeCount,
                potionCapacity: TaskController.potionCapacity,
                currentPotionCategories: currentPotionCategories,
                baseRewardXp: TaskController.potionRewardXp,
                varietyBonusXp: 10,
                varietyCategoryCount: currentPotionCategories.toSet().length,
                canDrinkPotion: canDrinkPotion,
                isDrinkingPotion: false,
                celebrationCount: 0,
                onDrinkPotion: onDrinkPotion ?? () {},
              ),
            ],
          ),
        ),
      ),
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

Future<void> _scrollToTopView(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('potion-bottle-tap-target')),
    -160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Color? _toggleColor(WidgetTester tester, Finder finder) {
  final widget = tester.widget<AnimatedContainer>(finder);
  final decoration = widget.decoration! as BoxDecoration;
  return decoration.color;
}

int _channelValue(Color color, int shift) {
  return (color.toARGB32() >> shift) & 0xFF;
}

class _CharacterAvatarHarness extends StatefulWidget {
  const _CharacterAvatarHarness({
    this.disableAnimations = false,
    this.onAvatarTap,
  });

  final bool disableAnimations;
  final VoidCallback? onAvatarTap;

  @override
  State<_CharacterAvatarHarness> createState() =>
      _CharacterAvatarHarnessState();
}

class _CharacterAvatarHarnessState extends State<_CharacterAvatarHarness> {
  int _interactionCount = 0;

  void _handleTap() {
    widget.onAvatarTap?.call();
    setState(() {
      _interactionCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: widget.disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: CharacterAvatar(
              stats: const CharacterStats(
                strength: 2,
                vitality: 45,
                wisdom: 4,
                mindfulness: 5,
              ),
              celebrationCount: 0,
              interactionCount: _interactionCount,
              onTap: _handleTap,
            ),
          ),
        ),
      ),
    );
  }
}
