import 'package:progress_potion/models/task_session_state.dart';

abstract class TaskService {
  Future<TaskSessionState> loadState();

  Future<void> saveState(TaskSessionState state);
}
