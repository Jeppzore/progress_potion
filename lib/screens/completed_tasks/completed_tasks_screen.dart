import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/widgets/task_tile.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key, required this.taskController});

  final TaskController taskController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: taskController,
      builder: (context, _) {
        if (taskController.error != null) {
          return const _AsyncStateMessage(
            icon: Icons.warning_amber_rounded,
            title: 'The cauldron needs a reset.',
            message: 'We could not load tasks for this session.',
          );
        }

        if (taskController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedTasks = taskController.completedTasks;

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
                child: _BackdropGlow(
                  size: 280,
                  color: const Color(0x334B8B70),
                ),
              ),
              Positioned(
                top: 90,
                left: -60,
                child: _BackdropGlow(
                  size: 220,
                  color: const Color(0x22E06B4C),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Completed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (completedTasks.isEmpty)
                    const _EmptyStateCard(title: 'Nothing completed yet')
                  else
                    for (final task in completedTasks) ...[
                      TaskTile(task: task),
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
