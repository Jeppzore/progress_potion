import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';
import 'package:progress_potion/widgets/potion_progress_card.dart';
import 'package:progress_potion/widgets/potion_reward_dialog.dart';
import 'package:progress_potion/widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.taskController,
    this.feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
  });

  final TaskController taskController;
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Duration _taskCompletionAnimationDuration = Duration(
    milliseconds: 440,
  );

  bool _isDrinkingPotion = false;
  int _celebrationCount = 0;
  final Set<String> _completingTaskIds = <String>{};

  Future<void> _removeActiveTask(String id) async {
    await widget.taskController.removeActiveTask(id);
  }

  Future<void> _markTaskAsFavorite(Task task) async {
    widget.feedbackSoundPlayer.play(FeedbackSound.buttonTap);
    await widget.taskController.markTaskAsFavorite(task.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to favorites.')));
  }

  Future<void> _markTaskAsStarter(Task task) async {
    widget.feedbackSoundPlayer.play(FeedbackSound.buttonTap);
    await widget.taskController.markTaskAsStarter(task.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved as a starter task.')));
  }

  Future<void> _completeTask(Task task) async {
    if (_completingTaskIds.contains(task.id)) {
      return;
    }

    final wasActive = widget.taskController.activeTasks.any(
      (activeTask) => activeTask.id == task.id,
    );
    if (!wasActive) {
      return;
    }

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (!disableAnimations) {
      setState(() {
        _completingTaskIds.add(task.id);
      });
      await Future<void>.delayed(_taskCompletionAnimationDuration);
      if (!mounted) {
        return;
      }
    }

    try {
      await widget.taskController.completeTask(task.id);
      if (!mounted) {
        return;
      }

      widget.feedbackSoundPlayer.play(FeedbackSound.taskComplete);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not complete this task.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _completingTaskIds.remove(task.id);
        });
      }
    }
  }

  Future<void> _drinkPotion(BuildContext context) async {
    if (_isDrinkingPotion) {
      return;
    }

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    widget.feedbackSoundPlayer.play(FeedbackSound.potionDrink);

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
          feedbackSoundPlayer: widget.feedbackSoundPlayer,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                    feedbackSoundPlayer: widget.feedbackSoundPlayer,
                    onDrinkPotion: () => _drinkPotion(context),
                  ),
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Active Tasks'),
                  const SizedBox(height: 10),
                  if (activeTasks.isEmpty)
                    const _EmptyStateCard(title: 'No active tasks')
                  else
                    for (final task in activeTasks) ...[
                      TaskTile(
                        key: ValueKey('active-task-${task.id}'),
                        task: task,
                        isFavorite: widget.taskController.isTaskFavorite(
                          task.id,
                        ),
                        isStarter: widget.taskController.isTaskStarter(task.id),
                        isCompleting: _completingTaskIds.contains(task.id),
                        onComplete: _completingTaskIds.contains(task.id)
                            ? null
                            : () => _completeTask(task),
                        onRemove: _completingTaskIds.contains(task.id)
                            ? null
                            : () => _removeActiveTask(task.id),
                        onFavorite: _completingTaskIds.contains(task.id)
                            ? null
                            : () => _markTaskAsFavorite(task),
                        onStarter: _completingTaskIds.contains(task.id)
                            ? null
                            : () => _markTaskAsStarter(task),
                      ),
                      const SizedBox(height: 10),
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
