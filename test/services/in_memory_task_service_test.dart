import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';

void main() {
  late InMemoryTaskService service;

  setUp(() {
    service = InMemoryTaskService();
  });

  test('listTasks returns the seeded tasks', () async {
    final tasks = await service.listTasks();

    expect(tasks, hasLength(3));
    expect(tasks.map((task) => task.title), contains('Brew morning focus'));
    expect(tasks.map((task) => task.category), contains(TaskCategory.work));
    expect(tasks.any((task) => task.isCompleted), isTrue);
  });

  test('addTask inserts a new incomplete task at the top', () async {
    final created = await service.addTask(
      title: 'Plan the next sprint',
      category: TaskCategory.study,
      description: 'Capture the next three priorities.',
    );
    final tasks = await service.listTasks();

    expect(created.title, 'Plan the next sprint');
    expect(created.category, TaskCategory.study);
    expect(created.isCompleted, isFalse);
    expect(tasks.first.title, 'Plan the next sprint');
    expect(tasks.first.category, TaskCategory.study);
  });

  test('completeTask marks a task complete and is idempotent', () async {
    final firstCompletion = await service.completeTask('ship-one-tiny-step');
    final secondCompletion = await service.completeTask('ship-one-tiny-step');

    expect(firstCompletion?.isCompleted, isTrue);
    expect(secondCompletion?.isCompleted, isTrue);
  });
}
