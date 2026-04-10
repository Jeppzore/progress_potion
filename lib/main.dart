import 'package:flutter/widgets.dart';

import 'package:progress_potion/app/progress_potion_app.dart';
import 'package:progress_potion/services/shared_preferences_task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProgressPotionApp(
      taskService: SharedPreferencesTaskService(preferences: preferences),
    ),
  );
}
