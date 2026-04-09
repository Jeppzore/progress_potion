enum HabitFrequency {
  daily,
  weekdays,
  weekly;

  String get label => switch (this) {
    HabitFrequency.daily => 'Daily cadence',
    HabitFrequency.weekdays => 'Weekday cadence',
    HabitFrequency.weekly => 'Weekly cadence',
  };
}
