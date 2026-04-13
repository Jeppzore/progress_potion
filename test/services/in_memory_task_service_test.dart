import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';

void main() {
  late InMemoryTaskService service;

  setUp(() {
    service = InMemoryTaskService();
  });

  test('loadState returns the seeded session state', () async {
    final state = await service.loadState();

    expect(state.tasks, hasLength(3));
    expect(
      state.tasks.map((task) => task.title),
      contains('Brew morning focus'),
    );
    expect(
      state.tasks.map((task) => task.category),
      contains(TaskCategory.work),
    );
    expect(state.tasks.any((task) => task.isCompleted), isTrue);
    expect(state.totalXp, 0);
    expect(state.stats, CharacterStats.zero);
    expect(state.potionChargeCategories, [TaskCategory.work]);
  });

  test('saveState replaces the current in-memory snapshot', () async {
    final nextState = TaskSessionState(
      tasks: const [
        Task(
          id: 'plan-the-next-sprint',
          title: 'Plan the next sprint',
          category: TaskCategory.study,
          description: 'Capture the next three priorities.',
        ),
      ],
      totalXp: 40,
      stats: const CharacterStats(
        strength: 1,
        vitality: 2,
        wisdom: 3,
        mindfulness: 4,
      ),
      potionChargeCategories: const [TaskCategory.study],
    );

    await service.saveState(nextState);
    final state = await service.loadState();

    expect(state.tasks.first.title, 'Plan the next sprint');
    expect(state.tasks.first.category, TaskCategory.study);
    expect(state.totalXp, 40);
    expect(state.stats.wisdom, 3);
    expect(state.potionChargeCategories, [TaskCategory.study]);
  });
}
