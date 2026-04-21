import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/screens/admin_tools/admin_tools_screen.dart';
import 'package:progress_potion/screens/add_task/add_task_screen.dart';
import 'package:progress_potion/screens/completed_tasks/completed_tasks_screen.dart';
import 'package:progress_potion/screens/favorites/favorites_screen.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';
import 'package:progress_potion/services/task_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.taskService,
    this.feedbackSoundPlayer,
  });

  final TaskService taskService;
  final FeedbackSoundPlayer? feedbackSoundPlayer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final TaskController _taskController;
  late final FeedbackSoundPlayer _feedbackSoundPlayer;
  late final bool _ownsFeedbackSoundPlayer;
  late final Future<void> _initialLoad;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController(taskService: widget.taskService);
    _ownsFeedbackSoundPlayer = widget.feedbackSoundPlayer == null;
    _feedbackSoundPlayer = widget.feedbackSoundPlayer ?? FeedbackSoundService();
    unawaited(_feedbackSoundPlayer.preload());
    _initialLoad = _taskController.loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    if (_ownsFeedbackSoundPlayer) {
      _feedbackSoundPlayer.dispose();
    }
    super.dispose();
  }

  Future<void> _openAddTaskScreen() async {
    _feedbackSoundPlayer.play(FeedbackSound.buttonTap);
    await _initialLoad;
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddTaskScreen(
          taskController: _taskController,
          feedbackSoundPlayer: _feedbackSoundPlayer,
        ),
      ),
    );
  }

  Future<void> _openAdminTools() async {
    if (!kDebugMode) {
      return;
    }

    await _initialLoad;
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminToolsScreen(taskController: _taskController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: kDebugMode
            ? GestureDetector(
                key: const ValueKey('admin-tools-entry'),
                behavior: HitTestBehavior.opaque,
                onLongPress: _openAdminTools,
                child: const Text('ProgressPotion'),
              )
            : const Text('ProgressPotion'),
        actions: [
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                key: const ValueKey('task-library-action'),
                onPressed: _openAddTaskScreen,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Add Task'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            taskController: _taskController,
            feedbackSoundPlayer: _feedbackSoundPlayer,
          ),
          FavoritesScreen(
            taskController: _taskController,
            feedbackSoundPlayer: _feedbackSoundPlayer,
          ),
          CompletedTasksScreen(taskController: _taskController),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index != _selectedIndex) {
            _feedbackSoundPlayer.play(FeedbackSound.buttonTap);
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_drink_outlined),
            selectedIcon: Icon(Icons.local_drink),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}
