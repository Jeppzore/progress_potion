enum HabitFrequency { daily, weekdays, weekly }

extension HabitFrequencyLabel on HabitFrequency {
  String get label => switch (this) {
    HabitFrequency.daily => 'Daily cadence',
    HabitFrequency.weekdays => 'Weekday cadence',
    HabitFrequency.weekly => 'Weekly cadence',
  };
}
