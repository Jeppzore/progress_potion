import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/task_service.dart';

class TaskController extends ChangeNotifier {
  TaskController({required TaskService taskService})
    : _taskService = taskService;

  static const int potionCapacity = 3;
  static const int potionRewardXp = 30;
  static const int varietyBonusXpPerCategory = 5;

  final TaskService _taskService;

  bool _isLoading = true;
  bool _hasSeededPotionCharge = false;
  Object? _error;
  List<Task> _tasks = const [];
  final Set<String> _completingTaskIds = <String>{};
  List<TaskCategory> _potionChargeCategories = const [];
  int _totalXp = 0;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);
  List<Task> get activeTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  int get totalCount => _tasks.length;
  int get completedCount => completedTasks.length;
  int get potionChargeCount => _potionChargeCategories.length;
  UnmodifiableListView<TaskCategory> get potionChargeCategories {
    return UnmodifiableListView(_potionChargeCategories);
  }

  int get totalXp => _totalXp;
  int get xp => totalXp;
  bool get canDrinkPotion => potionChargeCount >= potionCapacity;
  int get currentPotionUniqueCategoryCount {
    return _currentPotionCategories.toSet().length;
  }

  int get currentPotionVarietyBonusXp {
    return currentPotionUniqueCategoryCount * varietyBonusXpPerCategory;
  }

  double get potionProgress {
    return (potionChargeCount / potionCapacity).clamp(0, 1).toDouble();
  }

  Iterable<TaskCategory> get _currentPotionCategories {
    return _potionChargeCategories.take(potionCapacity);
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _taskService.listTasks();
      if (!_hasSeededPotionCharge) {
        _potionChargeCategories = [
          for (final task in completedTasks) task.category,
        ];
        _hasSeededPotionCharge = true;
      }
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    required TaskCategory category,
    String description = '',
  }) async {
    final task = await _taskService.addTask(
      title: title.trim(),
      category: category,
      description: description.trim(),
    );
    _tasks = [task, ..._tasks];
    notifyListeners();
  }

  Future<void> completeTask(String id) async {
    final currentIndex = _tasks.indexWhere((task) => task.id == id);
    if (currentIndex == -1 ||
        _tasks[currentIndex].isCompleted ||
        _completingTaskIds.contains(id)) {
      return;
    }

    _completingTaskIds.add(id);

    try {
      final updatedTask = await _taskService.completeTask(id);
      if (updatedTask == null) {
        return;
      }

      _tasks = [
        for (final task in _tasks)
          if (task.id == id) updatedTask else task,
      ];
      _potionChargeCategories = [
        ..._potionChargeCategories,
        updatedTask.category,
      ];
      notifyListeners();
    } finally {
      _completingTaskIds.remove(id);
    }
  }

  PotionRewardResult? drinkPotion() {
    if (!canDrinkPotion) {
      return null;
    }

    final consumedCategories = _currentPotionCategories.toList();
    final uniqueCategoryCount = consumedCategories.toSet().length;
    final result = PotionRewardResult(
      baseXp: potionRewardXp,
      varietyBonusXp: uniqueCategoryCount * varietyBonusXpPerCategory,
      uniqueCategoryCount: uniqueCategoryCount,
    );

    _potionChargeCategories = _potionChargeCategories
        .skip(potionCapacity)
        .toList();
    _totalXp += result.totalXp;
    notifyListeners();
    return result;
  }
}

class PotionRewardResult {
  const PotionRewardResult({
    required this.baseXp,
    required this.varietyBonusXp,
    required this.uniqueCategoryCount,
  });

  final int baseXp;
  final int varietyBonusXp;
  final int uniqueCategoryCount;

  int get totalXp => baseXp + varietyBonusXp;
}
