import 'package:flutter/material.dart';
import 'package:progress_potion/app/app_tab.dart';
import 'package:progress_potion/screens/home/home_screen.dart';
import 'package:progress_potion/screens/tasks/task_screen.dart';
import 'package:progress_potion/services/habit_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.habitService});

  final HabitService habitService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _selectedTab = AppTab.home;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedTab = AppTab.values[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProgressPotion')),
      body: IndexedStack(
        index: _selectedTab.index,
        children: [
          HomeScreen(habitService: widget.habitService),
          TaskScreen(habitService: widget.habitService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab.index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_motion_outlined),
            selectedIcon: Icon(Icons.auto_awesome_motion),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
