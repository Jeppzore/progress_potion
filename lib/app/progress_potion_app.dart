import 'package:flutter/material.dart';
import 'package:progress_potion/app/app_shell.dart';
import 'package:progress_potion/core/theme/app_theme.dart';
import 'package:progress_potion/services/habit_service.dart';
import 'package:progress_potion/services/in_memory_habit_service.dart';

class ProgressPotionApp extends StatelessWidget {
  const ProgressPotionApp({super.key, HabitService? habitService})
    : _habitService = habitService ?? const InMemoryHabitService();

  final HabitService _habitService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgressPotion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppShell(habitService: _habitService),
    );
  }
}
