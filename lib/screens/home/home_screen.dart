import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/widgets/potion_progress_card.dart';
import 'package:progress_potion/widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDrinkingPotion = false;

  Future<void> _drinkPotion(BuildContext context) async {
    if (_isDrinkingPotion) {
      return;
    }

    setState(() {
      _isDrinkingPotion = true;
    });

    final reward = await widget.taskController.drinkPotion();
    if (reward == null) {
      if (mounted) {
        setState(() {
          _isDrinkingPotion = false;
        });
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) {
      return;
    }

    final categoryLabel = reward.uniqueCategoryCount == 1
        ? 'category'
        : 'categories';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Potion claimed'),
          content: Text(
            'Base reward: +${reward.baseXp} XP\n'
            'Variety bonus: +${reward.varietyBonusXp} XP '
            '(${reward.uniqueCategoryCount} $categoryLabel)\n'
            'Total gained: +${reward.totalXp} XP\n'
            'Total XP: ${widget.taskController.totalXp}\n\n'
            'Your next potion is already brewing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nice'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isDrinkingPotion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.taskController,
      builder: (context, _) {
        if (widget.taskController.error != null) {
          return const _AsyncStateMessage(
            icon: Icons.warning_amber_rounded,
            title: 'The cauldron needs a reset.',
            message: 'We could not load tasks for this session.',
          );
        }

        if (widget.taskController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeTasks = widget.taskController.activeTasks;
        final completedTasks = widget.taskController.completedTasks;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            PotionProgressCard(
              xp: widget.taskController.totalXp,
              progress: widget.taskController.potionProgress,
              potionChargeCount: widget.taskController.potionChargeCount,
              potionCapacity: TaskController.potionCapacity,
              baseRewardXp: TaskController.potionRewardXp,
              varietyBonusXp: widget.taskController.currentPotionVarietyBonusXp,
              varietyCategoryCount:
                  widget.taskController.currentPotionUniqueCategoryCount,
              canDrinkPotion: widget.taskController.canDrinkPotion,
              isDrinkingPotion: _isDrinkingPotion,
              onDrinkPotion: () => _drinkPotion(context),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Active Tasks',
              subtitle: activeTasks.isEmpty
                  ? 'No active tasks yet. Add one to start brewing.'
                  : 'Complete tasks to fill the potion.',
            ),
            const SizedBox(height: 12),
            if (activeTasks.isEmpty)
              const _EmptyStateCard(
                title: 'No active tasks',
                message:
                    'Tap Add task to brew a fresh objective for this session.',
              )
            else
              for (final task in activeTasks) ...[
                TaskTile(
                  task: task,
                  onComplete: () => widget.taskController.completeTask(task.id),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Completed Tasks',
              subtitle: 'Completed tasks will appear here once you finish one.',
            ),
            const SizedBox(height: 12),
            if (completedTasks.isEmpty)
              const _EmptyStateCard(
                title: 'Nothing completed yet',
                message:
                    'Complete an active task to earn XP and bottle progress.',
              )
            else
              for (final task in completedTasks) ...[
                TaskTile(task: task),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.message});

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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AsyncStateMessage extends StatelessWidget {
  const _AsyncStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
