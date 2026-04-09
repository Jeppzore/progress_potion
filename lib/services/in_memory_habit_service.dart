import 'package:progress_potion/models/habit.dart';
import 'package:progress_potion/models/habit_frequency.dart';
import 'package:progress_potion/services/habit_service.dart';

class InMemoryHabitService implements HabitService {
  const InMemoryHabitService();

  static const List<Habit> _seedHabits = [
    Habit(
      id: 'morning-elixir-walk',
      name: 'Morning Elixir Walk',
      description:
          'Step outside before breakfast and let the day begin on purpose.',
      frequency: HabitFrequency.daily,
      currentStreak: 6,
      targetSessionsPerWeek: 7,
      isCompletedToday: true,
    ),
    Habit(
      id: 'deep-work-brew',
      name: 'Deep Work Brew',
      description:
          'Protect a focused block for the one task that matters most.',
      frequency: HabitFrequency.weekdays,
      currentStreak: 4,
      targetSessionsPerWeek: 5,
    ),
    Habit(
      id: 'strength-tonic',
      name: 'Strength Tonic',
      description:
          'Stack a short strength session to keep long-term progress visible.',
      frequency: HabitFrequency.weekly,
      currentStreak: 2,
      targetSessionsPerWeek: 3,
    ),
  ];

  @override
  Future<Habit?> getHabitById(String id) {
    return Future.value(
      _seedHabits.where((habit) => habit.id == id).firstOrNull,
    );
  }

  @override
  Future<List<Habit>> listHabits() {
    return Future.value(List<Habit>.unmodifiable(_seedHabits));
  }
}
