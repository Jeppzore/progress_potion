import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/widgets/potion_progress_card.dart';
import 'package:progress_potion/widgets/potion_reward_dialog.dart';
import 'package:progress_potion/widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDrinkingPotion = false;
  int _celebrationCount = 0;

  Future<void> _drinkPotion(BuildContext context) async {
    if (_isDrinkingPotion) {
      return;
    }

    final disableAnimations = MediaQuery.of(context).disableAnimations;

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

    if (mounted) {
      setState(() {
        _celebrationCount += 1;
      });
    }

    final delay = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return PotionRewardDialog(
          reward: reward,
          totalXp: widget.taskController.totalXp,
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

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F2E9), Color(0xFFF1E8DA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -40,
                child: _BackdropGlow(size: 280, color: const Color(0x334B8B70)),
              ),
              Positioned(
                top: 90,
                left: -60,
                child: _BackdropGlow(size: 220, color: const Color(0x22E06B4C)),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  PotionProgressCard(
                    xp: widget.taskController.totalXp,
                    stats: widget.taskController.stats,
                    progress: widget.taskController.potionProgress,
                    potionChargeCount: widget.taskController.potionChargeCount,
                    potionCapacity: TaskController.potionCapacity,
                    currentPotionCategories:
                        widget.taskController.currentPotionCategories,
                    baseRewardXp: TaskController.potionRewardXp,
                    varietyBonusXp:
                        widget.taskController.currentPotionVarietyBonusXp,
                    varietyCategoryCount:
                        widget.taskController.currentPotionUniqueCategoryCount,
                    canDrinkPotion: widget.taskController.canDrinkPotion,
                    isDrinkingPotion: _isDrinkingPotion,
                    celebrationCount: _celebrationCount,
                    onDrinkPotion: () => _drinkPotion(context),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Active Tasks',
                    subtitle: activeTasks.isEmpty
                        ? 'No active tasks yet. Add one to start brewing.'
                        : 'Complete tasks to fill the potion with category energy.',
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
                        onComplete: () =>
                            widget.taskController.completeTask(task.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    title: 'Completed Tasks',
                    subtitle:
                        'Finished tasks stay here and their energy remains stored in the potion queue.',
                  ),
                  const SizedBox(height: 12),
                  if (completedTasks.isEmpty)
                    const _EmptyStateCard(
                      title: 'Nothing completed yet',
                      message:
                          'Complete an active task to store a charge toward your next potion.',
                    )
                  else
                    for (final task in completedTasks) ...[
                      TaskTile(task: task),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyMedium),
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
