import 'package:flutter/material.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/widgets/character_avatar.dart';

class PotionProgressCard extends StatelessWidget {
  const PotionProgressCard({
    super.key,
    required this.xp,
    required this.stats,
    required this.progress,
    required this.potionChargeCount,
    required this.potionCapacity,
    required this.currentPotionCategories,
    required this.baseRewardXp,
    required this.varietyBonusXp,
    required this.varietyCategoryCount,
    required this.canDrinkPotion,
    required this.isDrinkingPotion,
    required this.celebrationCount,
    required this.onDrinkPotion,
  });

  final int xp;
  final CharacterStats stats;
  final double progress;
  final int potionChargeCount;
  final int potionCapacity;
  final List<TaskCategory> currentPotionCategories;
  final int baseRewardXp;
  final int varietyBonusXp;
  final int varietyCategoryCount;
  final bool canDrinkPotion;
  final bool isDrinkingPotion;
  final int celebrationCount;
  final VoidCallback onDrinkPotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spokenChargeCount = potionChargeCount.clamp(0, potionCapacity);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label:
          'Hero section. Potion has $spokenChargeCount of $potionCapacity charges. Total XP $xp. Strength ${stats.strength}. Vitality ${stats.vitality}. Wisdom ${stats.wisdom}. Mindfulness ${stats.mindfulness}.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              const Color(0xFFF5EFE2),
              theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -20,
                child: _GlowOrb(
                  size: 220,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                right: -40,
                bottom: -80,
                child: _GlowOrb(
                  size: 260,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 720;

                    final potionPane = _PotionPane(
                      progress: progress,
                      potionChargeCount: potionChargeCount,
                      potionCapacity: potionCapacity,
                      currentPotionCategories: currentPotionCategories,
                      canDrinkPotion: canDrinkPotion,
                      isDrinkingPotion: isDrinkingPotion,
                      totalRewardPreview: baseRewardXp + varietyBonusXp,
                      varietyBonusXp: varietyBonusXp,
                      varietyCategoryCount: varietyCategoryCount,
                      disableAnimations: disableAnimations,
                      onDrinkPotion: onDrinkPotion,
                    );
                    final companionPane = _CompanionPane(
                      xp: xp,
                      stats: stats,
                      celebrationCount: celebrationCount,
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          potionPane,
                          const SizedBox(height: 24),
                          companionPane,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: potionPane),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: companionPane),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotionPane extends StatelessWidget {
  const _PotionPane({
    required this.progress,
    required this.potionChargeCount,
    required this.potionCapacity,
    required this.currentPotionCategories,
    required this.canDrinkPotion,
    required this.isDrinkingPotion,
    required this.totalRewardPreview,
    required this.varietyBonusXp,
    required this.varietyCategoryCount,
    required this.disableAnimations,
    required this.onDrinkPotion,
  });

  final double progress;
  final int potionChargeCount;
  final int potionCapacity;
  final List<TaskCategory> currentPotionCategories;
  final bool canDrinkPotion;
  final bool isDrinkingPotion;
  final int totalRewardPreview;
  final int varietyBonusXp;
  final int varietyCategoryCount;
  final bool disableAnimations;
  final VoidCallback onDrinkPotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryLabel = varietyCategoryCount == 1 ? 'category' : 'categories';
    final headline = canDrinkPotion
        ? 'Potion is ready to drink'
        : 'Brew your next level';
    final subtitle = canDrinkPotion
        ? 'Claim this potion to bank XP and convert the stored categories into permanent stats.'
        : 'Complete tasks to build a full potion. Stats only increase when you drink a finished brew.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Pill(
              icon: Icons.auto_awesome_rounded,
              label: canDrinkPotion
                  ? 'Ready now'
                  : '$potionChargeCount of $potionCapacity charges',
            ),
            _Pill(
              icon: Icons.bolt_rounded,
              label: '+$totalRewardPreview XP preview',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          headline,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 360),
            child: _PotionBottle(
              progress: progress,
              isFull: canDrinkPotion,
              disableAnimations: disableAnimations,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      canDrinkPotion ? 'Reward preview' : 'Current brew',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Variety bonus: +$varietyBonusXp XP from $varietyCategoryCount $categoryLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentPotionCategories.isEmpty
                    ? [
                        _CategoryChip(
                          label: 'No essence stored yet',
                          color: theme.colorScheme.surfaceContainerHighest,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ]
                    : [
                        for (final category in currentPotionCategories)
                          _CategoryChip(
                            label: category.displayName,
                            color: _categoryColor(category),
                            textColor: Colors.white,
                          ),
                      ],
              ),
              const SizedBox(height: 16),
              if (canDrinkPotion)
                FilledButton.icon(
                  onPressed: isDrinkingPotion ? null : onDrinkPotion,
                  icon: const Icon(Icons.local_drink_rounded),
                  label: Text(
                    isDrinkingPotion ? 'Collecting...' : 'Drink Potion',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                )
              else
                Text(
                  'Keep stacking categories to reach the next drinkable potion.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanionPane extends StatelessWidget {
  const _CompanionPane({
    required this.xp,
    required this.stats,
    required this.celebrationCount,
  });

  final int xp;
  final CharacterStats stats;
  final int celebrationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Potionkeeper',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your companion grows each time a full potion is claimed.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Center(child: CharacterAvatar(celebrationCount: celebrationCount)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatCard(
                label: 'XP',
                value: xp,
                icon: Icons.stars_rounded,
                color: theme.colorScheme.primary,
              ),
              for (final entry in stats.entries)
                _StatCard(
                  label: entry.key.displayName,
                  value: entry.value,
                  icon: switch (entry.key) {
                    CharacterStat.strength => Icons.fitness_center_rounded,
                    CharacterStat.vitality => Icons.favorite_rounded,
                    CharacterStat.wisdom => Icons.auto_stories_rounded,
                    CharacterStat.mindfulness => Icons.spa_rounded,
                  },
                  color: switch (entry.key) {
                    CharacterStat.strength => const Color(0xFFCD6A43),
                    CharacterStat.vitality => const Color(0xFFBD5757),
                    CharacterStat.wisdom => const Color(0xFF3966C4),
                    CharacterStat.mindfulness => const Color(0xFF4B8B70),
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

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

class _PotionBottle extends StatefulWidget {
  const _PotionBottle({
    required this.progress,
    required this.isFull,
    required this.disableAnimations,
  });

  final double progress;
  final bool isFull;
  final bool disableAnimations;

  @override
  State<_PotionBottle> createState() => _PotionBottleState();
}

class _PotionBottleState extends State<_PotionBottle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _PotionBottle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disableAnimations != oldWidget.disableAnimations) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    if (widget.disableAnimations) {
      _loopController.stop();
      return;
    }

    if (!_loopController.isAnimating) {
      _loopController.repeat();
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationDuration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 900);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.progress.clamp(0.0, 1.0)),
      duration: animationDuration,
      curve: Curves.easeInOutCubicEmphasized,
      builder: (context, animatedProgress, _) {
        return AspectRatio(
          aspectRatio: 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(
                    alpha: widget.isFull ? 0.22 : 0.08,
                  ),
                  blurRadius: widget.isFull ? 44 : 18,
                  spreadRadius: widget.isFull ? 2 : 0,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: const _PotionBottleClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          const Color(0xFFE6ECFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: animatedProgress.clamp(0.0, 1.0),
                            widthFactor: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF5FE1C8),
                                        const Color(0xFF1FA5A4),
                                        theme.colorScheme.primary,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                if (!widget.disableAnimations)
                                  AnimatedBuilder(
                                    animation: _loopController,
                                    builder: (context, _) {
                                      return Align(
                                        alignment: Alignment(
                                          -0.2,
                                          1 - (_loopController.value * 2),
                                        ),
                                        child: FractionallySizedBox(
                                          widthFactor: 1,
                                          heightFactor: 0.3,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.22,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (!widget.disableAnimations)
                                  ..._bubbleLayers(animatedProgress),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 24,
                          child: Container(
                            width: 18,
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PotionBottlePainter(
                      outlineColor: theme.colorScheme.primary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  child: Container(
                    width: 86,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A4E2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _bubbleLayers(double progress) {
    final bubbleTravel = (1 - _loopController.value) * 150;
    final opacity = (0.25 + (progress * 0.35)).clamp(0.18, 0.55);

    return [
      Positioned(
        bottom: 22 + bubbleTravel,
        left: 54,
        child: _Bubble(size: 10, opacity: opacity),
      ),
      Positioned(
        bottom: 34 + ((bubbleTravel + 42) % 140),
        right: 60,
        child: _Bubble(size: 7, opacity: opacity * 0.9),
      ),
      Positioned(
        bottom: 18 + ((bubbleTravel + 88) % 120),
        right: 42,
        child: _Bubble(size: 12, opacity: opacity * 0.75),
      ),
    ];
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _PotionBottleClipper extends CustomClipper<Path> {
  const _PotionBottleClipper();

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final neckWidth = width * 0.24;
    final neckInset = (width - neckWidth) / 2;

    return Path()
      ..moveTo(width * 0.35, height * 0.04)
      ..quadraticBezierTo(width * 0.35, 0, width * 0.4, 0)
      ..lineTo(width * 0.6, 0)
      ..quadraticBezierTo(width * 0.65, 0, width * 0.65, height * 0.04)
      ..lineTo(neckInset + neckWidth, height * 0.16)
      ..quadraticBezierTo(
        width * 0.78,
        height * 0.24,
        width * 0.82,
        height * 0.32,
      )
      ..quadraticBezierTo(
        width * 0.98,
        height * 0.48,
        width * 0.88,
        height * 0.76,
      )
      ..quadraticBezierTo(
        width * 0.82,
        height * 0.94,
        width * 0.64,
        height * 0.98,
      )
      ..quadraticBezierTo(width * 0.5, height, width * 0.36, height * 0.98)
      ..quadraticBezierTo(
        width * 0.18,
        height * 0.94,
        width * 0.12,
        height * 0.76,
      )
      ..quadraticBezierTo(
        width * 0.02,
        height * 0.48,
        width * 0.18,
        height * 0.32,
      )
      ..quadraticBezierTo(width * 0.22, height * 0.24, neckInset, height * 0.16)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PotionBottlePainter extends CustomPainter {
  const _PotionBottlePainter({required this.outlineColor});

  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _PotionBottleClipper().getClip(size);
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(path, outlinePaint);

    final highlight = Path()
      ..moveTo(size.width * 0.3, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.34,
        size.width * 0.22,
        size.height * 0.7,
      );
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _PotionBottlePainter oldDelegate) {
    return oldDelegate.outlineColor != outlineColor;
  }
}

Color _categoryColor(TaskCategory category) {
  return switch (category) {
    TaskCategory.fitness => const Color(0xFFCD6A43),
    TaskCategory.home => const Color(0xFFBE5B6A),
    TaskCategory.study => const Color(0xFF3D62C9),
    TaskCategory.work => const Color(0xFF5A49B8),
    TaskCategory.hobby => const Color(0xFF3E8B6B),
  };
}
