import 'package:flutter/material.dart';

class PotionProgressCard extends StatelessWidget {
  const PotionProgressCard({
    super.key,
    required this.xp,
    required this.progress,
    required this.potionChargeCount,
    required this.potionCapacity,
    required this.baseRewardXp,
    required this.varietyBonusXp,
    required this.varietyCategoryCount,
    required this.canDrinkPotion,
    required this.isDrinkingPotion,
    required this.onDrinkPotion,
  });

  final int xp;
  final double progress;
  final int potionChargeCount;
  final int potionCapacity;
  final int baseRewardXp;
  final int varietyBonusXp;
  final int varietyCategoryCount;
  final bool canDrinkPotion;
  final bool isDrinkingPotion;
  final VoidCallback onDrinkPotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (progress * 100).round();
    final isFull = potionChargeCount >= potionCapacity;
    final spokenChargeCount = potionChargeCount.clamp(0, potionCapacity);
    final rewardPreview = canDrinkPotion
        ? 'Potion reward: $baseRewardXp XP + $varietyBonusXp variety bonus'
        : 'Potion reward: $baseRewardXp XP when full';
    final categoryLabel = varietyCategoryCount == 1 ? 'category' : 'categories';
    final bonusPreview = canDrinkPotion
        ? 'Variety bonus: +$varietyBonusXp XP from $varietyCategoryCount $categoryLabel'
        : 'Variety bonus so far: +$varietyBonusXp XP from $varietyCategoryCount $categoryLabel';
    final animationDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Semantics(
      label:
          'Potion progress, $spokenChargeCount of $potionCapacity charges filled, $progressPercent percent. $rewardPreview. $bonusPreview.',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF24584A), Color(0xFFDB9C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Potion progress',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFull
                  ? 'Potion is full'
                  : '$potionChargeCount of $potionCapacity charges filled',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total XP: $xp',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rewardPreview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bonusPreview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canDrinkPotion
                  ? 'The potion is ready to drink.'
                  : 'Complete tasks to fill the potion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return LinearProgressIndicator(
                    minHeight: 18,
                    value: animatedProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$progressPercent% filled',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canDrinkPotion)
                  Semantics(
                    button: true,
                    label: isDrinkingPotion
                        ? 'Drink Potion, claiming reward'
                        : 'Drink Potion, available',
                    child: FilledButton.icon(
                      onPressed: isDrinkingPotion ? null : onDrinkPotion,
                      icon: const Icon(Icons.local_drink),
                      label: Text(
                        isDrinkingPotion ? 'Claiming...' : 'Drink Potion',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
