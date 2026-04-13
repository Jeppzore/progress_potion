import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';

void main() {
  test('Task round trips through JSON', () {
    const task = Task(
      id: 'study-session',
      title: 'Study session',
      category: TaskCategory.study,
      description: 'Read one chapter.',
      isCompleted: true,
    );

    final decoded = Task.fromJson(task.toJson());

    expect(decoded.id, task.id);
    expect(decoded.title, task.title);
    expect(decoded.category, task.category);
    expect(decoded.description, task.description);
    expect(decoded.isCompleted, task.isCompleted);
  });

  test('TaskSessionState round trips through JSON', () {
    final state = TaskSessionState(
      tasks: const [
        Task(
          id: 'work-task',
          title: 'Work task',
          category: TaskCategory.work,
          isCompleted: true,
        ),
        Task(id: 'home-task', title: 'Home task', category: TaskCategory.home),
      ],
      totalXp: 85,
      stats: const CharacterStats(
        strength: 2,
        vitality: 4,
        wisdom: 6,
        mindfulness: 8,
      ),
      potionChargeCategories: const [TaskCategory.work, TaskCategory.home],
    );

    final decoded = TaskSessionState.fromJson(state.toJson());

    expect(decoded.tasks.map((task) => task.id), ['work-task', 'home-task']);
    expect(decoded.totalXp, 85);
    expect(decoded.stats.strength, 2);
    expect(decoded.stats.mindfulness, 8);
    expect(decoded.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.home,
    ]);
  });

  test('TaskSessionState migrates schema v1 sessions with zeroed stats', () {
    final decoded = TaskSessionState.fromJson({
      'schemaVersion': 1,
      'tasks': [
        {
          'id': 'legacy-task',
          'title': 'Legacy task',
          'description': '',
          'category': 'work',
          'isCompleted': true,
        },
      ],
      'totalXp': 30,
      'potionChargeCategories': ['work'],
    });

    expect(decoded.totalXp, 30);
    expect(decoded.stats.strength, 0);
    expect(decoded.stats.vitality, 0);
    expect(decoded.stats.wisdom, 0);
    expect(decoded.stats.mindfulness, 0);
  });

  test('TaskCategory rejects unknown storage values', () {
    expect(
      () => TaskCategory.fromStorageValue('wellness'),
      throwsA(isA<FormatException>()),
    );
  });

  test('TaskSessionState rejects non-object task entries', () {
    expect(
      () => TaskSessionState.fromJson({
        'schemaVersion': TaskSessionState.schemaVersion,
        'tasks': ['not a task'],
        'totalXp': 0,
        'stats': const {
          'strength': 0,
          'vitality': 0,
          'wisdom': 0,
          'mindfulness': 0,
        },
        'potionChargeCategories': <String>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('TaskSessionState rejects missing stats for schema v2', () {
    expect(
      () => TaskSessionState.fromJson({
        'schemaVersion': TaskSessionState.schemaVersion,
        'tasks': const [],
        'totalXp': 0,
        'potionChargeCategories': const <String>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
