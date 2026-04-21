import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';

class PotionRewardDialog extends StatelessWidget {
  const PotionRewardDialog({
    super.key,
    required this.reward,
    required this.totalXp,
    this.feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
  });

  final PotionRewardResult reward;
  final int totalXp;
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statGains = reward.statGains.entries
        .where((entry) => entry.value > 0)
        .toList();
    final categoryLabel = reward.uniqueCategoryCount == 1
        ? 'category'
        : 'categories';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.local_drink_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Rewards Collected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your potion converted stored energy into XP and permanent character growth.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total XP gained',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '+${reward.totalXp} XP',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _RewardChip(
                          label: 'Base reward',
                          value: '+${reward.baseXp} XP',
                        ),
                        _RewardChip(
                          label: 'Variety bonus',
                          value:
                              '+${reward.varietyBonusXp} XP from ${reward.uniqueCategoryCount} $categoryLabel',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Stat gains',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in statGains)
                    _StatGainChip(stat: entry.key, value: entry.value),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Total XP now: $totalXp',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    feedbackSoundPlayer.play(FeedbackSound.buttonTap);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGainChip extends StatelessWidget {
  const _StatGainChip({required this.stat, required this.value});

  final CharacterStat stat;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (stat) {
      CharacterStat.strength => Icons.fitness_center_rounded,
      CharacterStat.vitality => Icons.favorite_rounded,
      CharacterStat.wisdom => Icons.auto_stories_rounded,
      CharacterStat.mindfulness => Icons.spa_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            stat.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$value',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
