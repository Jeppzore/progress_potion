import 'package:flutter/material.dart';
import 'package:progress_potion/models/habit.dart';

class HabitPreviewCard extends StatelessWidget {
  const HabitPreviewCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = habit.isCompletedToday
        ? 'Completed today'
        : 'Queued today';
    final statusColor = habit.isCompletedToday
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    habit.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(habit.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HabitMetaChip(
                  icon: Icons.local_fire_department_outlined,
                  label: '${habit.currentStreak} day streak',
                ),
                _HabitMetaChip(
                  icon: Icons.repeat,
                  label: habit.frequency.label,
                ),
                _HabitMetaChip(
                  icon: Icons.track_changes_outlined,
                  label: '${habit.targetSessionsPerWeek} sessions/week',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitMetaChip extends StatelessWidget {
  const _HabitMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
