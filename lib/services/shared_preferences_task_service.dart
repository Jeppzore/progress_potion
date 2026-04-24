import 'dart:convert';

import 'package:progress_potion/models/default_task_session_state.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTaskService implements TaskService {
  SharedPreferencesTaskService({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String storageKey = 'progress_potion.session.v5';
  static const String legacyStorageKey = 'progress_potion.session.v4';
  static const String olderLegacyStorageKey = 'progress_potion.session.v3';
  static const String oldestLegacyStorageKey = 'progress_potion.session.v2';
  static const String oldestSupportedLegacyStorageKey =
      'progress_potion.session.v1';

  final SharedPreferences _preferences;

  @override
  Future<TaskSessionState> loadState() async {
    final savedState = _preferences.getString(storageKey);
    final legacyState = _preferences.getString(legacyStorageKey);
    final olderLegacyState = _preferences.getString(olderLegacyStorageKey);
    final oldestLegacyState = _preferences.getString(oldestLegacyStorageKey);
    final oldestSupportedLegacyState = _preferences.getString(
      oldestSupportedLegacyStorageKey,
    );
    final rawState =
        savedState ??
        legacyState ??
        olderLegacyState ??
        oldestLegacyState ??
        oldestSupportedLegacyState;
    if (rawState == null) {
      final seedState = createDefaultTaskSessionState();
      await saveState(seedState);
      return seedState;
    }

    final decoded = jsonDecode(rawState);
    if (decoded is! Map) {
      throw const FormatException('Saved task session must be a JSON object.');
    }

    final state = TaskSessionState.fromJson(Map<String, Object?>.from(decoded));

    if (savedState == null) {
      await saveState(state);
    }

    return state;
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

    if (_preferences.containsKey(legacyStorageKey)) {
      await _preferences.remove(legacyStorageKey);
    }
    if (_preferences.containsKey(olderLegacyStorageKey)) {
      await _preferences.remove(olderLegacyStorageKey);
    }
    if (_preferences.containsKey(oldestLegacyStorageKey)) {
      await _preferences.remove(oldestLegacyStorageKey);
    }
    if (_preferences.containsKey(oldestSupportedLegacyStorageKey)) {
      await _preferences.remove(oldestSupportedLegacyStorageKey);
    }
  }
}
