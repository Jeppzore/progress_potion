import 'package:progress_potion/models/habit.dart';

abstract class HabitService {
  Future<List<Habit>> listHabits();

  Future<Habit?> getHabitById(String id);
}
