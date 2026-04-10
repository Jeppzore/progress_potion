import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/task_service.dart';

class InMemoryTaskService implements TaskService {
  InMemoryTaskService({TaskSessionState? initialState})
    : _state = initialState ?? seedState;

  static TaskSessionState get seedState {
    return TaskSessionState(
      tasks: _seedTasks,
      totalXp: 0,
      potionChargeCategories: [
        for (final task in _seedTasks)
          if (task.isCompleted) task.category,
      ],
    );
  }

  static const List<Task> _seedTasks = [
    Task(
      id: 'brew-morning-focus',
      title: 'Brew morning focus',
      category: TaskCategory.work,
      description: 'Choose the one win that matters most before opening chat.',
      isCompleted: true,
    ),
    Task(
      id: 'refill-water-flask',
      title: 'Refill water flask',
      category: TaskCategory.fitness,
      description:
          'Set yourself up for the next work block with one small reset.',
    ),
    Task(
      id: 'ship-one-tiny-step',
      title: 'Ship one tiny step',
      category: TaskCategory.hobby,
      description:
          'Finish something concrete, even if it only takes ten minutes.',
    ),
  ];

  TaskSessionState _state;

  @override
  Future<TaskSessionState> loadState() async {
    return _state;
  }

  @override
  Future<void> saveState(TaskSessionState state) async {
    _state = state;
  }
}
