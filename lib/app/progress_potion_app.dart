import 'package:flutter/material.dart';
import 'package:progress_potion/app/app_shell.dart';
import 'package:progress_potion/core/theme/app_theme.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';
import 'package:progress_potion/services/in_memory_task_service.dart';
import 'package:progress_potion/services/task_service.dart';

class ProgressPotionApp extends StatelessWidget {
  ProgressPotionApp({
    super.key,
    TaskService? taskService,
    FeedbackSoundPlayer? feedbackSoundPlayer,
  }) : _taskService = taskService ?? InMemoryTaskService(),
       _feedbackSoundPlayer = feedbackSoundPlayer;

  final TaskService _taskService;
  final FeedbackSoundPlayer? _feedbackSoundPlayer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgressPotion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppShell(
        taskService: _taskService,
        feedbackSoundPlayer: _feedbackSoundPlayer,
      ),
    );
  }
}
