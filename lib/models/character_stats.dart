import 'package:progress_potion/models/task.dart';

enum CharacterStat {
  strength('Strength'),
  vitality('Vitality'),
  wisdom('Wisdom'),
  mindfulness('Mindfulness');

  const CharacterStat(this.displayName);

  final String displayName;

  static CharacterStat fromTaskCategory(TaskCategory category) {
    return switch (category) {
      TaskCategory.fitness => CharacterStat.strength,
      TaskCategory.home => CharacterStat.vitality,
      TaskCategory.study || TaskCategory.work => CharacterStat.wisdom,
      TaskCategory.hobby => CharacterStat.mindfulness,
    };
  }
}

class CharacterStats {
  const CharacterStats({
    required this.strength,
    required this.vitality,
    required this.wisdom,
    required this.mindfulness,
  });

  static const CharacterStats zero = CharacterStats(
    strength: 0,
    vitality: 0,
    wisdom: 0,
    mindfulness: 0,
  );

  final int strength;
  final int vitality;
  final int wisdom;
  final int mindfulness;

  int operator [](CharacterStat stat) {
    return switch (stat) {
      CharacterStat.strength => strength,
      CharacterStat.vitality => vitality,
      CharacterStat.wisdom => wisdom,
      CharacterStat.mindfulness => mindfulness,
    };
  }

  Iterable<MapEntry<CharacterStat, int>> get entries => [
    MapEntry(CharacterStat.strength, strength),
    MapEntry(CharacterStat.vitality, vitality),
    MapEntry(CharacterStat.wisdom, wisdom),
    MapEntry(CharacterStat.mindfulness, mindfulness),
  ];

  bool get isZero =>
      strength == 0 && vitality == 0 && wisdom == 0 && mindfulness == 0;

  CharacterStats copyWith({
    int? strength,
    int? vitality,
    int? wisdom,
    int? mindfulness,
  }) {
    return CharacterStats(
      strength: strength ?? this.strength,
      vitality: vitality ?? this.vitality,
      wisdom: wisdom ?? this.wisdom,
      mindfulness: mindfulness ?? this.mindfulness,
    );
  }

  CharacterStats add(CharacterStats other) {
    return CharacterStats(
      strength: strength + other.strength,
      vitality: vitality + other.vitality,
      wisdom: wisdom + other.wisdom,
      mindfulness: mindfulness + other.mindfulness,
    );
  }

  Map<String, Object> toJson() {
    return {
      'strength': strength,
      'vitality': vitality,
      'wisdom': wisdom,
      'mindfulness': mindfulness,
    };
  }

  factory CharacterStats.fromJson(Map<String, Object?> json) {
    return CharacterStats(
      strength: _readStatValue(json, key: 'strength'),
      vitality: _readStatValue(json, key: 'vitality'),
      wisdom: _readStatValue(json, key: 'wisdom'),
      mindfulness: _readStatValue(json, key: 'mindfulness'),
    );
  }

  factory CharacterStats.fromCategories(Iterable<TaskCategory> categories) {
    var strength = 0;
    var vitality = 0;
    var wisdom = 0;
    var mindfulness = 0;

    for (final category in categories) {
      switch (CharacterStat.fromTaskCategory(category)) {
        case CharacterStat.strength:
          strength += 1;
        case CharacterStat.vitality:
          vitality += 1;
        case CharacterStat.wisdom:
          wisdom += 1;
        case CharacterStat.mindfulness:
          mindfulness += 1;
      }
    }

    return CharacterStats(
      strength: strength,
      vitality: vitality,
      wisdom: wisdom,
      mindfulness: mindfulness,
    );
  }

  static int _readStatValue(Map<String, Object?> json, {required String key}) {
    final value = json[key];
    if (value is! int || value < 0) {
      throw FormatException(
        'Character stat "$key" must be a non-negative int.',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterStats &&
        other.strength == strength &&
        other.vitality == vitality &&
        other.wisdom == wisdom &&
        other.mindfulness == mindfulness;
  }

  @override
  int get hashCode => Object.hash(strength, vitality, wisdom, mindfulness);
}
