import 'dart:convert';

import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTaskService implements TaskService {
  SharedPreferencesTaskService({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String storageKey = 'progress_potion.session.v1';

  final SharedPreferences _preferences;

  @override
  Future<TaskSessionState> loadState() async {
    final savedState = _preferences.getString(storageKey);
    if (savedState == null) {
      final seedState = InMemoryTaskService.seedState;
      await saveState(seedState);
      return seedState;
    }

    final decoded = jsonDecode(savedState);
    if (decoded is! Map) {
      throw const FormatException('Saved task session must be a JSON object.');
    }

    return TaskSessionState.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> saveState(TaskSessionState state) async {
    final didSave = await _preferences.setString(
      storageKey,
      jsonEncode(state.toJson()),
    );
    if (!didSave) {
      throw StateError('Could not save task session.');
    }
  }
}
