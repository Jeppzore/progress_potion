import 'package:flutter/material.dart';
import 'package:progress_potion/models/habit.dart';
import 'package:progress_potion/services/habit_service.dart';
import 'package:progress_potion/widgets/habit_task_tile.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, required this.habitService});

  final HabitService habitService;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late final Future<List<Habit>> _habitsFuture;

  @override
  void initState() {
    super.initState();
    _habitsFuture = widget.habitService.listHabits();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Habit>>(
      future: _habitsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TaskStateCard(
            title: 'Task lanes are offline.',
            message:
                'The placeholder queue depends on the habit service responding cleanly.',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = snapshot.data!;
        final queuedHabits = habits
            .where((habit) => !habit.isCompletedToday)
            .toList();
        final completedHabits = habits
            .where((habit) => habit.isCompletedToday)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _TaskStateCard(
              title: 'Task Forge',
              message:
                  'Phase 2 will add task creation and completion. For now, this screen maps each habit into a queue-friendly lane.',
            ),
            const SizedBox(height: 20),
            Text(
              'Ready today',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (queuedHabits.isEmpty)
              const _EmptyLaneMessage(
                message:
                    'Everything in the demo queue is already marked complete for today.',
              )
            else
              for (final habit in queuedHabits) ...[
                HabitTaskTile(
                  habit: habit,
                  laneLabel: 'Queued',
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 20),
            Text(
              'Already bottled',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (completedHabits.isEmpty)
              const _EmptyLaneMessage(
                message:
                    'Completed habits will show up here once Phase 2 can record them.',
              )
            else
              for (final habit in completedHabits) ...[
                HabitTaskTile(
                  habit: habit,
                  laneLabel: 'Complete',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _TaskStateCard extends StatelessWidget {
  const _TaskStateCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyLaneMessage extends StatelessWidget {
  const _EmptyLaneMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
