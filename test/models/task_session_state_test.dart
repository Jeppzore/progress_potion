import 'package:flutter_test/flutter_test.dart';
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
      potionChargeCategories: const [TaskCategory.work, TaskCategory.home],
    );

    final decoded = TaskSessionState.fromJson(state.toJson());

    expect(decoded.tasks.map((task) => task.id), ['work-task', 'home-task']);
    expect(decoded.totalXp, 85);
    expect(decoded.potionChargeCategories, [
      TaskCategory.work,
      TaskCategory.home,
    ]);
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
        'potionChargeCategories': <String>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
