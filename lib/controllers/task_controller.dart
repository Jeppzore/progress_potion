import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/default_task_session_state.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/models/task_session_state.dart';
import 'package:progress_potion/services/task_service.dart';

enum FavoriteSort { mostUsed, libraryOrder }

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
  List<TaskCatalogItem> _catalogItems = const [];
  final Set<String> _completingTaskIds = <String>{};
  bool _isClaimingPotionReward = false;
  List<TaskCategory> _potionChargeCategories = const [];
  int _totalXp = 0;
  CharacterStats _stats = CharacterStats.zero;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);
  UnmodifiableListView<TaskCatalogItem> get catalogItems =>
      UnmodifiableListView(_catalogItems);
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

  UnmodifiableListView<TaskCategory> get currentPotionCategories {
    return UnmodifiableListView(_currentPotionCategories.toList());
  }

  int get totalXp => _totalXp;
  int get xp => totalXp;
  CharacterStats get stats => _stats;
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
      _replaceState(state);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TaskCatalogItem> getCatalogByCategory(TaskCategory category) {
    final items = _catalogItems
        .where((item) => item.category == category)
        .toList();
    items.sort(_compareCatalogItems);
    return items;
  }

  List<TaskCatalogItem> favoriteCatalogItems({
    FavoriteSort sort = FavoriteSort.mostUsed,
  }) {
    final items = _catalogItems.where((item) => item.isFavorite).toList();
    if (sort == FavoriteSort.mostUsed) {
      items.sort(_compareFavoritesByMostUsed);
    } else {
      items.sort(_compareCatalogItems);
    }
    return items;
  }

  bool isTaskFavorite(String taskId) {
    for (final task in _tasks) {
      if (task.id == taskId) {
        return _findCatalogItemForTask(task)?.isFavorite ?? false;
      }
    }
    return false;
  }

  Future<void> addTask({
    required String title,
    required TaskCategory category,
    String description = '',
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title is required.');
    }
    final catalogItem =
        _findCatalogItem(trimmedTitle, category, trimmedDescription) ??
        _buildCatalogItem(
          title: trimmedTitle,
          category: category,
          description: trimmedDescription,
        );
    final task = _buildActiveTaskFromCatalog(catalogItem);
    final nextCatalogItems =
        _catalogItems.any((item) => item.id == catalogItem.id)
        ? _catalogItems
        : [catalogItem, ..._catalogItems];

    await _saveAndApplyState(
      _buildState(tasks: [task, ..._tasks], catalogItems: nextCatalogItems),
    );
  }

  Future<TaskCatalogItem> createCatalogItem({
    required String title,
    required TaskCategory category,
    String description = '',
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title is required.');
    }
    final existing = _findCatalogItem(
      trimmedTitle,
      category,
      trimmedDescription,
    );
    if (existing != null) {
      return existing;
    }

    final catalogItem = _buildCatalogItem(
      title: trimmedTitle,
      category: category,
      description: trimmedDescription,
    );

    await _saveAndApplyState(
      _buildState(catalogItems: [catalogItem, ..._catalogItems]),
    );
    return catalogItem;
  }

  Future<void> toggleFavorite(String catalogItemId) async {
    final currentIndex = _catalogItems.indexWhere(
      (item) => item.id == catalogItemId,
    );
    if (currentIndex == -1) {
      return;
    }

    final currentItem = _catalogItems[currentIndex];
    final updatedItem = currentItem.copyWith(
      isFavorite: !currentItem.isFavorite,
    );
    final nextCatalogItems = [
      for (final item in _catalogItems)
        if (item.id == catalogItemId) updatedItem else item,
    ];

    await _saveAndApplyState(_buildState(catalogItems: nextCatalogItems));
  }

  Future<void> markTaskAsFavorite(String taskId) async {
    final currentIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (currentIndex == -1 || _tasks[currentIndex].isCompleted) {
      return;
    }

    final task = _tasks[currentIndex];
    final existing = _findCatalogItemForTask(task);
    if (existing == null) {
      final catalogItem = _buildCatalogItem(
        title: task.title,
        category: task.category,
        description: task.description,
      ).copyWith(isFavorite: true);
      await _saveAndApplyState(
        _buildState(catalogItems: [catalogItem, ..._catalogItems]),
      );
      return;
    }

    if (existing.isFavorite) {
      return;
    }

    final nextCatalogItems = [
      for (final item in _catalogItems)
        if (item.id == existing.id) item.copyWith(isFavorite: true) else item,
    ];

    await _saveAndApplyState(_buildState(catalogItems: nextCatalogItems));
  }

  Future<void> activateCatalogItem(String catalogItemId) async {
    final currentIndex = _catalogItems.indexWhere(
      (item) => item.id == catalogItemId,
    );
    if (currentIndex == -1) {
      return;
    }
    final catalogItem = _catalogItems[currentIndex];
    final alreadyActive = _tasks.any(
      (task) =>
          !task.isCompleted &&
          task.title == catalogItem.title &&
          task.category == catalogItem.category &&
          task.description == catalogItem.description,
    );
    if (alreadyActive) {
      return;
    }
    final task = _buildActiveTaskFromCatalog(catalogItem);

    await _saveAndApplyState(_buildState(tasks: [task, ..._tasks]));
  }

  Future<void> removeActiveTask(String taskId) async {
    final currentIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (currentIndex == -1 || _tasks[currentIndex].isCompleted) {
      return;
    }

    await _saveAndApplyState(
      _buildState(
        tasks: [
          for (final task in _tasks)
            if (task.id != taskId) task,
        ],
      ),
    );
  }

  Future<void> deleteUserCatalogItem(String catalogItemId) async {
    final currentIndex = _catalogItems.indexWhere(
      (item) => item.id == catalogItemId,
    );
    if (currentIndex == -1 || _catalogItems[currentIndex].isDefault) {
      return;
    }

    await _saveAndApplyState(
      _buildState(
        catalogItems: [
          for (final item in _catalogItems)
            if (item.id != catalogItemId) item,
        ],
      ),
    );
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
      final nextCatalogItems = _incrementCompletedCount(updatedTask);

      await _saveAndApplyState(
        _buildState(
          tasks: nextTasks,
          catalogItems: nextCatalogItems,
          potionChargeCategories: nextPotionChargeCategories,
        ),
      );
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
      final statGains = CharacterStats.fromCategories(consumedCategories);
      final result = PotionRewardResult(
        baseXp: potionRewardXp,
        varietyBonusXp: uniqueCategoryCount * varietyBonusXpPerCategory,
        uniqueCategoryCount: uniqueCategoryCount,
        statGains: statGains,
      );

      final nextPotionChargeCategories = _potionChargeCategories
          .skip(potionCapacity)
          .toList();
      await _saveAndApplyState(
        _buildState(
          totalXp: _totalXp + result.totalXp,
          stats: _stats.add(statGains),
          potionChargeCategories: nextPotionChargeCategories,
        ),
      );
      return result;
    } finally {
      _isClaimingPotionReward = false;
    }
  }

  Future<void> grantAdminProgress({
    required int xpDelta,
    required CharacterStats statDelta,
  }) async {
    if (xpDelta <= 0 && statDelta.isZero) {
      throw ArgumentError(
        'Admin progress must include a positive XP delta or stat gain.',
      );
    }
    if (xpDelta < 0) {
      throw ArgumentError.value(
        xpDelta,
        'xpDelta',
        'XP delta must be positive.',
      );
    }
    _validateNonNegativeStats(statDelta);

    await _saveAndApplyState(
      _buildState(totalXp: _totalXp + xpDelta, stats: _stats.add(statDelta)),
    );
  }

  Future<void> addAdminPotionCharge(TaskCategory category) async {
    await _saveAndApplyState(
      _buildState(
        potionChargeCategories: [..._potionChargeCategories, category],
      ),
    );
  }

  Future<void> resetProgressToSeedState() async {
    await _saveAndApplyState(createDefaultTaskSessionState());
  }

  void _replaceState(TaskSessionState state) {
    _tasks = state.tasks;
    _catalogItems = state.catalogItems;
    _potionChargeCategories = state.potionChargeCategories;
    _totalXp = state.totalXp;
    _stats = state.stats;
  }

  TaskSessionState _buildState({
    Iterable<Task>? tasks,
    Iterable<TaskCatalogItem>? catalogItems,
    int? totalXp,
    CharacterStats? stats,
    Iterable<TaskCategory>? potionChargeCategories,
  }) {
    return TaskSessionState(
      tasks: tasks ?? _tasks,
      catalogItems: catalogItems ?? _catalogItems,
      totalXp: totalXp ?? _totalXp,
      stats: stats ?? _stats,
      potionChargeCategories: potionChargeCategories ?? _potionChargeCategories,
    );
  }

  Future<void> _saveAndApplyState(TaskSessionState state) async {
    await _taskService.saveState(state);
    _replaceState(state);
    notifyListeners();
  }

  TaskCatalogItem _buildCatalogItem({
    required String title,
    required TaskCategory category,
    String description = '',
  }) {
    return TaskCatalogItem(
      id: _catalogItemIdForTitle(title),
      title: title.trim(),
      category: category,
      description: description.trim(),
      sortOrder: _nextCatalogSortOrder(),
    );
  }

  Task _buildActiveTaskFromCatalog(TaskCatalogItem catalogItem) {
    return catalogItem.toTask(id: _taskIdForTitle(catalogItem.title));
  }

  int _nextCatalogSortOrder() {
    var highestSortOrder = -1;
    for (final item in _catalogItems) {
      if (item.sortOrder > highestSortOrder) {
        highestSortOrder = item.sortOrder;
      }
    }
    return highestSortOrder + 1;
  }

  String _catalogItemIdForTitle(String title) {
    return 'catalog-${_slugify(title, _catalogItems.length + 1, _catalogSlugs)}';
  }

  String _taskIdForTitle(String title) {
    return _slugify(title, _tasks.length + 1, _tasks.map((task) => task.id));
  }

  int _compareCatalogItems(TaskCatalogItem a, TaskCatalogItem b) {
    if (a.isFavorite != b.isFavorite) {
      return a.isFavorite ? -1 : 1;
    }

    if (a.isDefault != b.isDefault) {
      return a.isDefault ? 1 : -1;
    }

    if (a.sortOrder != b.sortOrder) {
      return b.sortOrder.compareTo(a.sortOrder);
    }

    final titleComparison = a.title.compareTo(b.title);
    if (titleComparison != 0) {
      return titleComparison;
    }

    return a.id.compareTo(b.id);
  }

  int _compareFavoritesByMostUsed(TaskCatalogItem a, TaskCatalogItem b) {
    if (a.completedCount != b.completedCount) {
      return b.completedCount.compareTo(a.completedCount);
    }

    return _compareCatalogItems(a, b);
  }

  List<TaskCatalogItem> _incrementCompletedCount(Task task) {
    final matchingItem = _findCatalogItemForTask(task);
    if (matchingItem == null) {
      return _catalogItems;
    }

    return [
      for (final item in _catalogItems)
        if (item.id == matchingItem.id)
          item.copyWith(completedCount: item.completedCount + 1)
        else
          item,
    ];
  }

  TaskCatalogItem? _findCatalogItemForTask(Task task) {
    return _findCatalogItem(task.title, task.category, task.description);
  }

  TaskCatalogItem? _findCatalogItem(
    String title,
    TaskCategory category,
    String description,
  ) {
    for (final item in _catalogItems) {
      if (item.title == title &&
          item.category == category &&
          item.description == description) {
        return item;
      }
    }
    return null;
  }

  Iterable<String> get _catalogSlugs sync* {
    for (final item in _catalogItems) {
      if (item.id.startsWith('catalog-')) {
        yield item.id.substring('catalog-'.length);
      } else {
        yield item.id;
      }
    }
  }

  void _validateNonNegativeStats(CharacterStats stats) {
    for (final entry in stats.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key.name,
          'Stat delta must be non-negative.',
        );
      }
    }
  }

  String _slugify(
    String title,
    int fallbackSuffix,
    Iterable<String> existingIds,
  ) {
    final existingIdSet = existingIds.toSet();
    final normalized = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (normalized.isEmpty) {
      var blankCandidate = 'task-$fallbackSuffix';
      while (existingIdSet.contains(blankCandidate)) {
        fallbackSuffix += 1;
        blankCandidate = 'task-$fallbackSuffix';
      }
      return blankCandidate;
    }

    if (!existingIdSet.contains(normalized)) {
      return normalized;
    }

    var candidate = '$normalized-$fallbackSuffix';
    while (existingIdSet.contains(candidate)) {
      fallbackSuffix += 1;
      candidate = '$normalized-$fallbackSuffix';
    }
    return candidate;
  }
}

class PotionRewardResult {
  const PotionRewardResult({
    required this.baseXp,
    required this.varietyBonusXp,
    required this.uniqueCategoryCount,
    required this.statGains,
  });

  final int baseXp;
  final int varietyBonusXp;
  final int uniqueCategoryCount;
  final CharacterStats statGains;

  int get totalXp => baseXp + varietyBonusXp;
}
