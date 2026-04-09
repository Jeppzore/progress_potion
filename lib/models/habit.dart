import 'package:progress_potion/models/habit_frequency.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.currentStreak,
    required this.targetSessionsPerWeek,
    this.isCompletedToday = false,
  });

  final String id;
  final String name;
  final String description;
  final HabitFrequency frequency;
  final int currentStreak;
  final int targetSessionsPerWeek;
  final bool isCompletedToday;
}
