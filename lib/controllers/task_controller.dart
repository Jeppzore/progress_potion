import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/task_service.dart';

class TaskController extends ChangeNotifier {
  TaskController({required TaskService taskService})
    : _taskService = taskService;

  static const int potionCapacity = 3;
  static const int potionRewardXp = 30;
  static const int varietyBonusXpPerCategory = 5;

  final TaskService _taskService;

  bool _isLoading = true;
  Object? _error;
  List<Task> _tasks = const [];
  final Set<String> _completingTaskIds = <String>{};
  bool _isClaimingPotionReward = false;
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
      final state = await _taskService.loadState();
      _tasks = state.tasks;
      _potionChargeCategories = state.potionChargeCategories;
      _totalXp = state.totalXp;
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
    final task = Task(
      id: _slugify(title, _tasks.length + 1),
      title: title.trim(),
      category: category,
      description: description.trim(),
    );

    final nextTasks = [task, ..._tasks];
    await _saveState(tasks: nextTasks);
    _tasks = nextTasks;
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
      final updatedTask = _tasks[currentIndex].copyWith(isCompleted: true);
      final nextTasks = [
        for (final task in _tasks)
          if (task.id == id) updatedTask else task,
      ];
      final nextPotionChargeCategories = [
        ..._potionChargeCategories,
        updatedTask.category,
      ];

      await _saveState(
        tasks: nextTasks,
        potionChargeCategories: nextPotionChargeCategories,
      );
      _tasks = nextTasks;
      _potionChargeCategories = nextPotionChargeCategories;
      notifyListeners();
    } finally {
      _completingTaskIds.remove(id);
    }
  }

  Future<PotionRewardResult?> drinkPotion() async {
    if (!canDrinkPotion || _isClaimingPotionReward) {
      return null;
    }

    _isClaimingPotionReward = true;

    try {
      final consumedCategories = _currentPotionCategories.toList();
      final uniqueCategoryCount = consumedCategories.toSet().length;
      final result = PotionRewardResult(
        baseXp: potionRewardXp,
        varietyBonusXp: uniqueCategoryCount * varietyBonusXpPerCategory,
        uniqueCategoryCount: uniqueCategoryCount,
      );

      final nextPotionChargeCategories = _potionChargeCategories
          .skip(potionCapacity)
          .toList();
      final nextTotalXp = _totalXp + result.totalXp;

      await _saveState(
        totalXp: nextTotalXp,
        potionChargeCategories: nextPotionChargeCategories,
      );
      _potionChargeCategories = nextPotionChargeCategories;
      _totalXp = nextTotalXp;
      notifyListeners();
      return result;
    } finally {
      _isClaimingPotionReward = false;
    }
  }

  Future<void> _saveState({
    List<Task>? tasks,
    int? totalXp,
    List<TaskCategory>? potionChargeCategories,
  }) async {
    await _taskService.saveState(
      TaskSessionState(
        tasks: tasks ?? _tasks,
        totalXp: totalXp ?? _totalXp,
        potionChargeCategories:
            potionChargeCategories ?? _potionChargeCategories,
      ),
    );
  }

  String _slugify(String title, int fallbackSuffix) {
    final normalized = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (normalized.isEmpty) {
      return 'task-$fallbackSuffix';
    }

    if (_tasks.every((task) => task.id != normalized)) {
      return normalized;
    }

    return '$normalized-$fallbackSuffix';
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
