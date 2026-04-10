import 'package:progress_potion/models/task.dart';

abstract class TaskService {
  Future<List<Task>> listTasks();

  Future<Task> addTask({
    required String title,
    required TaskCategory category,
    String description,
  });

  Future<Task?> completeTask(String id);
}
