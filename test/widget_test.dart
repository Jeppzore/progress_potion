import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/screens/add_task/add_task_screen.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:progress_potion/widgets/character_avatar.dart';
import 'package:progress_potion/widgets/potion_progress_card.dart';
import 'package:progress_potion/widgets/potion_reward_dialog.dart';
import 'package:progress_potion/widgets/task_tile.dart';

void main() {
  testWidgets('renders the hero with potion view by default', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('ProgressPotion'), findsOneWidget);
    expect(find.text('Brew in progress'), findsOneWidget);
    expect(find.text('Potionkeeper'), findsNothing);
    expect(find.text('1 of 3 charges'), findsOneWidget);
    expect(find.text('Drink Potion'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Add Task'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

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
      expect(find.text('Brew in progress'), findsNothing);

      await _scrollToText(tester, 'Active Tasks');
      expect(find.text('Active Tasks'), findsOneWidget);
    },
  );

  testWidgets('bottom navigation preserves the active screen state', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.drag(
      find.byKey(const ValueKey('hero-page-view')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Potionkeeper'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-library-action')), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Brew morning focus'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-library-action')), findsNothing);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-library-action')), findsNothing);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(find.text('Potionkeeper'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-library-action')), findsOneWidget);
  });

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
    final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

    await _pumpPotionCard(
      tester,
      potionChargeCount: 1,
      currentPotionCategories: const [TaskCategory.fitness],
      feedbackSoundPlayer: feedbackSoundPlayer,
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
    expect(feedbackSoundPlayer.playedSounds, [FeedbackSound.potionFlask]);
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
    'completing a task turns the card green and slides it before moving it',
    (WidgetTester tester) async {
      final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

      await _pumpApp(
        tester,
        disableAnimations: false,
        feedbackSoundPlayer: feedbackSoundPlayer,
      );

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Complete'),
        80,
        scrollable: _activeTasksScrollable(),
      );
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.widgetWithText(FilledButton, 'Complete').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final completingCard = tester.widget<Card>(
        find.byKey(const ValueKey('task-tile-card-refill-water-flask')),
      );
      final completingSlide = tester.widget<AnimatedSlide>(
        find.byKey(const ValueKey('task-tile-slide-refill-water-flask')),
      );

      expect(find.text('Refill water flask'), findsOneWidget);
      expect(completingCard.color, const Color(0xFFE2F3E8));
      expect(completingSlide.offset.dx, greaterThan(0));
      expect(find.text('Done'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 440));
      await tester.pump();

      expect(feedbackSoundPlayer.playedSounds, [FeedbackSound.taskComplete]);
      expect(find.text('Refill water flask'), findsOneWidget);

      await tester.tap(find.text('Completed'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Refill water flask'), findsOneWidget);
    },
  );

  testWidgets(
    'reduced motion completes tasks without waiting for the slide animation',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Complete'),
        80,
        scrollable: _activeTasksScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Complete').first);
      await tester.pump();

      final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

      expect(
        homeScreen.taskController.completedTasks.any(
          (task) => task.id == 'refill-water-flask',
        ),
        isTrue,
      );
      expect(find.text('Refill water flask'), findsOneWidget);
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

  testWidgets('vitality selects resting, bending, and standing poses', (
    WidgetTester tester,
  ) async {
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

    final restingTorso = await torsoRectForVitality(0);
    expect(find.byKey(const ValueKey('avatar-pose-resting')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-seat')), findsOneWidget);

    final bendingTorso = await torsoRectForVitality(40);
    expect(find.byKey(const ValueKey('avatar-pose-bending')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-seat')), findsNothing);

    final standingTorso = await torsoRectForVitality(60);
    expect(
      find.byKey(const ValueKey('avatar-pose-standing-tall')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('avatar-seat')), findsNothing);

    final plateauTorso = await torsoRectForVitality(1000);

    expect(bendingTorso.top, lessThan(restingTorso.top));
    expect(standingTorso.top, lessThan(bendingTorso.top));
    expect((standingTorso.top - plateauTorso.top).abs(), lessThan(0.01));
    expect((standingTorso.height - plateauTorso.height).abs(), lessThan(0.01));
  });

  testWidgets('character tap triggers the bending balance reaction', (
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

    expect(find.byKey(const ValueKey('avatar-bending-reaction')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tapCount, 1);
    expect(
      find.byKey(const ValueKey('avatar-bending-reaction')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('avatar-sparkle-0')), findsNothing);
  });

  testWidgets('resting and standing poses use distinct tap reactions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _CharacterAvatarHarness(
        stats: CharacterStats(
          strength: 2,
          vitality: 0,
          wisdom: 4,
          mindfulness: 5,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 32));
    await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey('avatar-resting-reaction')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const _CharacterAvatarHarness(
        stats: CharacterStats(
          strength: 2,
          vitality: 60,
          wisdom: 4,
          mindfulness: 5,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 32));
    await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey('avatar-standing-tall-reaction')),
      findsOneWidget,
    );
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
      expect(
        find.byKey(const ValueKey('avatar-bending-reaction')),
        findsNothing,
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

    expect(data.label, 'Potionkeeper companion, finding balance');
    expect(data.hint, 'Tap for a balancing wobble');
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    semanticsHandle.dispose();
  });

  testWidgets(
    'character page wires avatar tap feedback through the hero view',
    (WidgetTester tester) async {
      final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

      await _pumpApp(tester, feedbackSoundPlayer: feedbackSoundPlayer);

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

      expect(find.text('Tap for a reaction'), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-tap-target')), findsOneWidget);

      feedbackSoundPlayer.playedSounds.clear();
      await tester.tap(find.byKey(const ValueKey('avatar-tap-target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(feedbackSoundPlayer.playedSounds, [
        FeedbackSound.characterInteract,
      ]);
      expect(
        find.byKey(const ValueKey('avatar-reduced-motion-pulse')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 220));
    },
  );

  testWidgets(
    'shows a larger task library category picker, sorts favorites first, and keeps new tasks in the library',
    (WidgetTester tester) async {
      final controller = _FakeLibraryTaskController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: AddTaskScreen(taskController: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task library'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Fitness'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Study'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('task-library-category-study'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('task-library-category-fitness')),
            )
            .showCheckmark,
        isFalse,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
      await tester.pumpAndSettle();

      final favoriteTop = tester.getTopLeft(find.text('Priority summary'));
      final starterBelow = tester.getTopLeft(find.text('Draft checklist'));
      expect(favoriteTop.dy, lessThan(starterBelow.dy));
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
      expect(find.textContaining('favorites'), findsNothing);
      expect(find.textContaining('starters'), findsNothing);

      await tester.ensureVisible(find.byIcon(Icons.star_border_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byIcon(Icons.star_border_rounded),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(controller.toggledFavoriteIds, ['study-starter']);

      await tester.ensureVisible(find.byIcon(Icons.play_circle_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byIcon(Icons.play_circle_outline_rounded).first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(controller.toggledStarterIds, ['study-favorite']);

      await tester.tap(find.text('Create new task'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task title'),
        'Write release summary',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Keep the update crisp.',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save to library'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save to library'));
      await tester.pumpAndSettle();

      expect(controller.createdTaskTitle, 'Write release summary');
      expect(controller.createdTaskCategory, TaskCategory.study);
      expect(controller.activatedTaskId, isNull);
      expect(find.text('Write release summary'), findsOneWidget);
      expect(find.text('Add to active'), findsWidgets);
    },
  );

  testWidgets(
    'adding a library task keeps the screen open and updates the active list',
    (WidgetTester tester) async {
      final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

      await _pumpApp(tester, feedbackSoundPlayer: feedbackSoundPlayer);

      await tester.tap(find.byKey(const ValueKey('task-library-action')));
      await tester.pumpAndSettle();
      expect(feedbackSoundPlayer.playedSounds, [FeedbackSound.buttonTap]);

      await tester.tap(find.text('Create new task'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task title'),
        'Plan weekly review',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Keep the session short.',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save to library'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save to library'));
      await tester.pumpAndSettle();
      expect(feedbackSoundPlayer.playedSounds.last, FeedbackSound.taskCreate);

      final addToActiveButton = find
          .widgetWithText(FilledButton, 'Add to active')
          .first;
      await tester.ensureVisible(addToActiveButton);
      await tester.pumpAndSettle();
      await tester.tap(addToActiveButton);
      await tester.pump();
      expect(feedbackSoundPlayer.playedSounds.last, FeedbackSound.taskCreate);

      expect(find.text('Task library'), findsOneWidget);
      expect(find.text('Plan weekly review'), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _scrollToText(tester, 'Active Tasks');

      expect(find.text('Plan weekly review'), findsOneWidget);
    },
  );

  testWidgets(
    'favorites tab renders favorite tasks with counts and sort controls',
    (WidgetTester tester) async {
      final service = InMemoryTaskService(
        initialState: TaskSessionState(
          tasks: const [],
          catalogItems: const [
            TaskCatalogItem(
              id: 'catalog-low-use',
              title: 'Low use',
              category: TaskCategory.work,
              isFavorite: true,
              sortOrder: 5,
              completedCount: 2,
            ),
            TaskCatalogItem(
              id: 'catalog-high-use',
              title: 'High use',
              category: TaskCategory.study,
              isFavorite: true,
              sortOrder: 1,
              completedCount: 4,
            ),
          ],
          totalXp: 0,
          stats: CharacterStats.zero,
          potionChargeCategories: const [],
        ),
      );

      await _pumpApp(tester, taskService: service);
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsWidgets);
      expect(find.text('Most used'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Completed 4 times'), findsOneWidget);
      expect(find.text('Completed 2 times'), findsOneWidget);

      final highUseTop = tester.getTopLeft(find.text('High use'));
      final lowUseTop = tester.getTopLeft(find.text('Low use'));
      expect(highUseTop.dy, lessThan(lowUseTop.dy));

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      final libraryLowUseTop = tester.getTopLeft(find.text('Low use'));
      final libraryHighUseTop = tester.getTopLeft(find.text('High use'));
      expect(libraryLowUseTop.dy, lessThan(libraryHighUseTop.dy));
    },
  );

  testWidgets(
    'active task favorite action adds the task to the favorites tab',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await _scrollToText(tester, 'Active Tasks');
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, '+ Favorite').first,
        80,
        scrollable: _activeTasksScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '+ Favorite').first);
      await tester.pumpAndSettle();

      expect(find.text('Favorited'), findsOneWidget);
      expect(find.text('Saved to favorites.'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('task-library-action')), findsNothing);
      expect(find.text('Refill water flask'), findsOneWidget);
      expect(find.text('Completed 0 times'), findsOneWidget);
      expect(find.text('Already active'), findsOneWidget);
    },
  );

  testWidgets('active task starter action keeps the task active after completion', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _scrollToText(tester, 'Active Tasks');
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, '+ Starter').first,
      80,
      scrollable: _activeTasksScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '+ Starter').first);
    await tester.pumpAndSettle();

    expect(find.text('Starter'), findsWidgets);
    expect(find.text('Saved as a starter task.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Complete').first,
      80,
      scrollable: _activeTasksScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Complete').first);
    await tester.pumpAndSettle();

    expect(find.text('Refill water flask'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Refill water flask'), findsOneWidget);
    expect(find.text('Starter'), findsWidgets);
  });

  testWidgets('failed library saves recover the create form for retry', (
    WidgetTester tester,
  ) async {
    final controller = _FailingLibraryTaskController();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: AddTaskScreen(taskController: controller)),
      ),
    );
    await tester.pumpAndSettle();

    final createTaskButton = find.widgetWithText(TextButton, 'Create new task');
    await tester.scrollUntilVisible(
      createTaskButton,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(createTaskButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task title'),
      'Retry later',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Save to library'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save to library'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save this task. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Save to library'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('task tiles expose remove and starter actions with larger titles', (
    WidgetTester tester,
  ) async {
    var removed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: TaskTile(
              task: const Task(
                id: 'stand-up',
                title: 'Plan the stand-up',
                category: TaskCategory.work,
                description: 'Keep the active list easy to trim.',
              ),
              onComplete: () {},
              onRemove: () {
                removed = true;
              },
              onStarter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('+ Starter'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Plan the stand-up')).style?.fontSize,
      20,
    );

    await tester.tap(find.text('Remove'));
    await tester.pump();

    expect(removed, isTrue);
  });

  testWidgets(
    'completing tasks fills the potion without awarding XP immediately',
    (WidgetTester tester) async {
      final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

      await _pumpApp(tester, feedbackSoundPlayer: feedbackSoundPlayer);

      final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(homeScreen.taskController.totalXp, 0);

      await _completeVisibleTask(tester);

      expect(feedbackSoundPlayer.playedSounds, [FeedbackSound.taskComplete]);
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

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsNWidgets(2));
      expect(find.text('Refill water flask'), findsOneWidget);
    },
  );

  testWidgets('tapping a full potion bottle drinks it and updates the hero', (
    WidgetTester tester,
  ) async {
    final feedbackSoundPlayer = _RecordingFeedbackSoundPlayer();

    await _pumpApp(tester, feedbackSoundPlayer: feedbackSoundPlayer);

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    await _completeVisibleTask(tester);
    await _completeVisibleTask(tester);

    expect(homeScreen.taskController.canDrinkPotion, isTrue);
    expect(homeScreen.taskController.totalXp, 0);

    await _scrollToTopView(tester);
    feedbackSoundPlayer.playedSounds.clear();
    await tester.tap(find.byKey(const ValueKey('potion-bottle-tap-target')));
    await tester.pumpAndSettle();

    expect(feedbackSoundPlayer.playedSounds.first, FeedbackSound.potionDrink);
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

  testWidgets('starter seed tasks stay active after completion', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));

    await _completeVisibleTask(tester);
    await _completeVisibleTask(tester);

    expect(homeScreen.taskController.activeTasks, isNotEmpty);
    expect(
      homeScreen.taskController.activeTasks.map((task) => task.title),
      containsAll(['Refill water flask', 'Ship one tiny step']),
    );
    expect(homeScreen.taskController.potionChargeCount, 3);
    expect(homeScreen.taskController.totalXp, 0);
    expect(find.text('No active tasks'), findsNothing);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Refill water flask'), findsOneWidget);
    expect(find.text('Ship one tiny step'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  TaskService? taskService,
  FeedbackSoundPlayer? feedbackSoundPlayer,
  bool disableAnimations = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: ProgressPotionApp(
        taskService: taskService,
        feedbackSoundPlayer:
            feedbackSoundPlayer ?? const NoOpFeedbackSoundPlayer(),
      ),
    ),
  );
  if (disableAnimations) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpPotionCard(
  WidgetTester tester, {
  double progress = 0.33,
  int potionChargeCount = 1,
  List<TaskCategory> currentPotionCategories = const [TaskCategory.fitness],
  bool canDrinkPotion = false,
  CharacterStats stats = CharacterStats.zero,
  FeedbackSoundPlayer feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
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
                feedbackSoundPlayer: feedbackSoundPlayer,
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

class _RecordingFeedbackSoundPlayer implements FeedbackSoundPlayer {
  final List<FeedbackSound> playedSounds = <FeedbackSound>[];
  var preloadCount = 0;
  var disposed = false;

  @override
  Future<void> preload() async {
    preloadCount += 1;
  }

  @override
  void play(FeedbackSound sound) {
    playedSounds.add(sound);
  }

  @override
  void dispose() {
    disposed = true;
  }
}

Future<void> _completeVisibleTask(WidgetTester tester) async {
  final completeButton = find.widgetWithText(FilledButton, 'Complete');
  await tester.scrollUntilVisible(
    completeButton,
    120,
    scrollable: _activeTasksScrollable(),
  );
  await tester.pumpAndSettle();
  await tester.tap(completeButton.first);
  await tester.pumpAndSettle();
}

Finder _activeTasksScrollable() {
  return find.byType(Scrollable).first;
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

class _NoOpTaskService implements TaskService {
  @override
  Future<TaskSessionState> loadState() async {
    return TaskSessionState(
      tasks: const [],
      catalogItems: const [],
      totalXp: 0,
      stats: CharacterStats.zero,
      potionChargeCategories: const [],
    );
  }

  @override
  Future<void> saveState(TaskSessionState state) async {}
}

class _FakeLibraryTaskController extends TaskController {
  _FakeLibraryTaskController() : super(taskService: _NoOpTaskService());

  final Map<TaskCategory, List<TaskCatalogItem>> _itemsByCategory = {
    TaskCategory.fitness: [
      TaskCatalogItem(
        id: 'fitness-starter',
        title: 'Water break',
        category: TaskCategory.fitness,
        description: 'Take a quick reset between blocks.',
        isStarter: true,
        isDefault: true,
      ),
      TaskCatalogItem(
        id: 'fitness-favorite',
        title: 'Stretch walk',
        category: TaskCategory.fitness,
        description: 'Move around once before lunch.',
        isFavorite: true,
      ),
    ],
    TaskCategory.study: [
      TaskCatalogItem(
        id: 'study-starter',
        title: 'Draft checklist',
        category: TaskCategory.study,
        description: 'Keep the next action obvious.',
        isStarter: true,
        isDefault: true,
      ),
      TaskCatalogItem(
        id: 'study-favorite',
        title: 'Priority summary',
        category: TaskCategory.study,
        description: 'Capture the important bits first.',
        isFavorite: true,
      ),
    ],
  };

  String? activatedTaskId;
  String? createdTaskTitle;
  TaskCategory? createdTaskCategory;
  final List<String> toggledFavoriteIds = <String>[];
  final List<String> toggledStarterIds = <String>[];

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

  @override
  List<TaskCatalogItem> getCatalogByCategory(TaskCategory category) {
    return List<TaskCatalogItem>.of(_itemsByCategory[category] ?? const []);
  }

  @override
  Future<TaskCatalogItem> createCatalogItem({
    required String title,
    required TaskCategory category,
    String description = '',
  }) async {
    createdTaskTitle = title;
    createdTaskCategory = category;
    final newItem = TaskCatalogItem(
      id: title.toLowerCase().replaceAll(' ', '-'),
      title: title,
      category: category,
      description: description,
    );
    _itemsByCategory.putIfAbsent(category, () => []).insert(0, newItem);
    notifyListeners();
    return newItem;
  }

  @override
  Future<void> activateCatalogItem(String id) async {
    activatedTaskId = id;
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    toggledFavoriteIds.add(id);
    TaskCatalogItem? item;
    for (final catalogItem in _itemsByCategory.values.expand(
      (items) => items,
    )) {
      if (catalogItem.id == id) {
        item = catalogItem;
        break;
      }
    }
    if (item == null) {
      return;
    }

    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    for (final entry in _itemsByCategory.entries) {
      final index = entry.value.indexWhere(
        (catalogItem) => catalogItem.id == id,
      );
      if (index != -1) {
        entry.value[index] = updatedItem;
        break;
      }
    }
    notifyListeners();
  }

  @override
  Future<void> toggleStarter(String id) async {
    toggledStarterIds.add(id);
    TaskCatalogItem? item;
    for (final catalogItem in _itemsByCategory.values.expand(
      (items) => items,
    )) {
      if (catalogItem.id == id) {
        item = catalogItem;
        break;
      }
    }
    if (item == null) {
      return;
    }

    final updatedItem = item.copyWith(isStarter: !item.isStarter);
    for (final entry in _itemsByCategory.entries) {
      final index = entry.value.indexWhere(
        (catalogItem) => catalogItem.id == id,
      );
      if (index != -1) {
        entry.value[index] = updatedItem;
        break;
      }
    }
    notifyListeners();
  }

  @override
  Future<void> deleteUserCatalogItem(String id) async {
    for (final items in _itemsByCategory.values) {
      items.removeWhere((item) => item.id == id);
    }
    notifyListeners();
  }
}

class _FailingLibraryTaskController extends _FakeLibraryTaskController {
  @override
  Future<TaskCatalogItem> createCatalogItem({
    required String title,
    required TaskCategory category,
    String description = '',
  }) async {
    throw StateError('Simulated save failure.');
  }
}

class _CharacterAvatarHarness extends StatefulWidget {
  const _CharacterAvatarHarness({
    this.disableAnimations = false,
    this.stats = const CharacterStats(
      strength: 2,
      vitality: 45,
      wisdom: 4,
      mindfulness: 5,
    ),
    this.onAvatarTap,
  });

  final bool disableAnimations;
  final CharacterStats stats;
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
              stats: widget.stats,
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
