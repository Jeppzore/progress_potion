import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/services/in_memory_habit_service.dart';

void main() {
  const service = InMemoryHabitService();

  test('listHabits returns the seeded habits', () async {
    final habits = await service.listHabits();

    expect(habits, hasLength(3));
    expect(habits.map((habit) => habit.name), contains('Morning Elixir Walk'));
    expect(habits.any((habit) => habit.isCompletedToday), isTrue);
  });

  test('getHabitById returns a matching habit or null', () async {
    final habit = await service.getHabitById('deep-work-brew');
    final missingHabit = await service.getHabitById('missing-habit');

    expect(habit?.name, 'Deep Work Brew');
    expect(missingHabit, isNull);
  });
}
