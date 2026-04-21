import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';
import 'package:progress_potion/widgets/character_avatar.dart';

class PotionProgressCard extends StatefulWidget {
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
    this.feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
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
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  State<PotionProgressCard> createState() => _PotionProgressCardState();
}

class _PotionProgressCardState extends State<PotionProgressCard> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  int _bottleJiggleCount = 0;
  final Map<int, double> _pageHeights = <int, double>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setPage(int index) {
    if (_currentPageIndex == index) {
      return;
    }

    widget.feedbackSoundPlayer.play(FeedbackSound.buttonTap);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePotionTap() {
    if (widget.isDrinkingPotion) {
      return;
    }

    if (widget.canDrinkPotion) {
      widget.onDrinkPotion();
      return;
    }

    widget.feedbackSoundPlayer.play(FeedbackSound.potionFlask);
    setState(() {
      _bottleJiggleCount += 1;
    });
  }

  void _updatePageHeight(int index, double height) {
    final normalizedHeight = height.ceilToDouble();
    final previousHeight = _pageHeights[index];
    if (previousHeight != null &&
        (previousHeight - normalizedHeight).abs() < 1) {
      return;
    }

    setState(() {
      _pageHeights[index] = normalizedHeight;
    });
  }

  double _heroHeightForWidth(double maxWidth) {
    if (maxWidth >= 900) {
      return 540;
    }
    if (maxWidth >= 720) {
      return 560;
    }
    if (maxWidth >= 520) {
      return 600;
    }
    return 630;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spokenChargeCount = widget.potionChargeCount.clamp(
      0,
      widget.potionCapacity,
    );
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label:
          'Hero section. ${_currentPageIndex == 0 ? 'Potion view' : 'Character view'}. Potion has $spokenChargeCount of ${widget.potionCapacity} charges. Total XP ${widget.xp}. Strength ${widget.stats.strength}. Vitality ${widget.stats.vitality}. Wisdom ${widget.stats.wisdom}. Mindfulness ${widget.stats.mindfulness}.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
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
          borderRadius: BorderRadius.circular(32),
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
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final potionPane = _PotionPane(
                      progress: widget.progress,
                      potionChargeCount: widget.potionChargeCount,
                      potionCapacity: widget.potionCapacity,
                      currentPotionCategories: widget.currentPotionCategories,
                      canDrinkPotion: widget.canDrinkPotion,
                      isDrinkingPotion: widget.isDrinkingPotion,
                      totalRewardPreview:
                          widget.baseRewardXp + widget.varietyBonusXp,
                      varietyBonusXp: widget.varietyBonusXp,
                      varietyCategoryCount: widget.varietyCategoryCount,
                      disableAnimations: disableAnimations,
                      jiggleCount: _bottleJiggleCount,
                      onDrinkPotion: widget.onDrinkPotion,
                      onPotionTap: _handlePotionTap,
                    );
                    final companionPane = _CompanionPane(
                      xp: widget.xp,
                      stats: widget.stats,
                      celebrationCount: widget.celebrationCount,
                      feedbackSoundPlayer: widget.feedbackSoundPlayer,
                    );
                    final fallbackHeroHeight = _heroHeightForWidth(
                      constraints.maxWidth,
                    );
                    final heroHeight = math.max(
                      _pageHeights[_currentPageIndex] ?? fallbackHeroHeight,
                      0.0,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: heroHeight,
                            child: PageView(
                              key: const ValueKey('hero-page-view'),
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPageIndex = index;
                                });
                              },
                              children: [
                                _HeroPage(
                                  key: const ValueKey('hero-page-potion'),
                                  onHeightChanged: (height) {
                                    _updatePageHeight(0, height);
                                  },
                                  child: potionPane,
                                ),
                                _HeroPage(
                                  key: const ValueKey('hero-page-character'),
                                  onHeightChanged: (height) {
                                    _updatePageHeight(1, height);
                                  },
                                  child: companionPane,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _HeroPageToggle(
                                key: const ValueKey('hero-page-toggle-0'),
                                label: 'Potion',
                                isSelected: _currentPageIndex == 0,
                                onTap: () => _setPage(0),
                              ),
                              _HeroPageToggle(
                                key: const ValueKey('hero-page-toggle-1'),
                                label: 'Character',
                                isSelected: _currentPageIndex == 1,
                                onTap: () => _setPage(1),
                              ),
                            ],
                          ),
                        ),
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

class _HeroPage extends StatelessWidget {
  const _HeroPage({
    super.key,
    required this.child,
    required this.onHeightChanged,
  });

  final Widget child;
  final ValueChanged<double> onHeightChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OverflowBox(
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: _MeasureSize(
            onChange: (size) => onHeightChanged(size.height),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Align(alignment: Alignment.topCenter, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this._onChange);

  ValueChanged<Size> _onChange;
  Size? _previousSize;

  set onChange(ValueChanged<Size> value) {
    _onChange = value;
  }

  @override
  void performLayout() {
    super.performLayout();

    final nextSize = size;
    if (_previousSize == nextSize) {
      return;
    }
    _previousSize = nextSize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChange(nextSize);
    });
  }
}

class _HeroPageToggle extends StatelessWidget {
  const _HeroPageToggle({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label top view',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          key: ValueKey('hero-page-toggle-pill-$label'),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.36)
                  : theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.45,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
    required this.jiggleCount,
    required this.onDrinkPotion,
    required this.onPotionTap,
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
  final int jiggleCount;
  final VoidCallback onDrinkPotion;
  final VoidCallback onPotionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryLabel = varietyCategoryCount == 1 ? 'category' : 'categories';
    final headline = canDrinkPotion ? 'Potion ready' : 'Brew in progress';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 14),
        Text(
          headline,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 236, maxHeight: 252),
            child: _PotionBottle(
              progress: progress,
              isFull: canDrinkPotion,
              categories: currentPotionCategories,
              disableAnimations: disableAnimations,
              jiggleCount: jiggleCount,
              onTap: onPotionTap,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                      canDrinkPotion ? 'Reward' : 'Brew',
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
                '+$varietyBonusXp variety from $varietyCategoryCount $categoryLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: currentPotionCategories.isEmpty
                    ? [
                        _CategoryChip(
                          label: 'No charges yet',
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
              const SizedBox(height: 14),
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
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanionPane extends StatefulWidget {
  const _CompanionPane({
    required this.xp,
    required this.stats,
    required this.celebrationCount,
    required this.feedbackSoundPlayer,
  });

  final int xp;
  final CharacterStats stats;
  final int celebrationCount;
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  State<_CompanionPane> createState() => _CompanionPaneState();
}

class _CompanionPaneState extends State<_CompanionPane> {
  int _characterInteractionCount = 0;

  void _handleCharacterTap() {
    widget.feedbackSoundPlayer.play(FeedbackSound.characterInteract);
    setState(() {
      _characterInteractionCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageHeadline = _companionHeadline(widget.stats.vitality);
    final stageBody = _companionBody(widget.stats);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.78),
            const Color(0xFFFFF6EA),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
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
            'Each claimed potion quietly sharpens your companion posture, mood, and presence.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFCF6), Color(0xFFF2E6D5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stageHeadline,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      'Tap for a reaction',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF9F0), Color(0xFFEAD8BE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE3C59A).withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 6,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.secondary.withValues(
                                  alpha: 0.20,
                                ),
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.55, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 18,
                        child: Container(
                          width: 176,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB88D67), Color(0xFF8D6649)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: CharacterAvatar(
                          size: const Size(190, 230),
                          stats: widget.stats,
                          celebrationCount: widget.celebrationCount,
                          interactionCount: _characterInteractionCount,
                          onTap: _handleCharacterTap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stageBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatCard(
                  label: 'XP',
                  value: widget.xp,
                  icon: Icons.stars_rounded,
                  color: theme.colorScheme.primary,
                ),
                for (final entry in widget.stats.entries)
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
          ),
        ],
      ),
    );
  }
}

String _companionHeadline(int vitality) {
  if (vitality >= 60) {
    return 'Standing tall';
  }
  if (vitality >= 25) {
    return 'Finding balance';
  }
  return 'Resting up';
}

String _companionBody(CharacterStats stats) {
  final totalGrowth = stats.entries.fold<int>(
    0,
    (sum, entry) => sum + entry.value,
  );
  final presence = totalGrowth == 0
      ? 'Your companion is just beginning the climb.'
      : 'Every full potion leaves a visible trace in their stance and expression.';

  if (stats.vitality >= 60) {
    return '$presence The companion now stands tall with longer lines and a proud, steady stance.';
  }
  if (stats.vitality >= 25) {
    return '$presence The companion is bent forward in motion, balancing between rest and a full upright pose.';
  }
  return '$presence Early gains keep the companion low and resting so the bigger posture payoff still feels earned.';
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
      constraints: const BoxConstraints(minWidth: 112, maxWidth: 156),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatStatValue(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatStatValue(int value) {
  if (value < 1000) {
    return '$value';
  }

  const units = ['K', 'M', 'B'];
  var compactValue = value.toDouble();

  for (final unit in units) {
    compactValue /= 1000;
    if (compactValue < 1000) {
      final roundedValue = compactValue >= 10
          ? compactValue.toStringAsFixed(0)
          : compactValue.toStringAsFixed(1);
      return '${roundedValue.replaceFirst(RegExp(r'\.0$'), '')}$unit';
    }
  }

  return value.toString();
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    required this.categories,
    required this.disableAnimations,
    required this.jiggleCount,
    required this.onTap,
  });

  final double progress;
  final bool isFull;
  final List<TaskCategory> categories;
  final bool disableAnimations;
  final int jiggleCount;
  final VoidCallback onTap;

  @override
  State<_PotionBottle> createState() => _PotionBottleState();
}

class _PotionBottleState extends State<_PotionBottle>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _jiggleController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _PotionBottle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disableAnimations != oldWidget.disableAnimations) {
      _syncAnimationState();
    }
    if (widget.jiggleCount != oldWidget.jiggleCount &&
        !widget.disableAnimations) {
      _jiggleController
        ..stop()
        ..forward(from: 0);
    }
  }

  void _syncAnimationState() {
    if (widget.disableAnimations) {
      _loopController.stop();
      _jiggleController.stop();
      return;
    }

    if (!_loopController.isAnimating) {
      _loopController.repeat();
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    _jiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blend = _resolvePotionBlend(widget.categories, theme);
    final animationDuration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 900);

    return AnimatedBuilder(
      animation: Listenable.merge([_loopController, _jiggleController]),
      builder: (context, _) {
        final jiggleOffset = widget.disableAnimations
            ? 0.0
            : math.sin(_jiggleController.value * math.pi * 5) *
                  10 *
                  (1 - _jiggleController.value);
        final jiggleRotation = widget.disableAnimations
            ? 0.0
            : math.sin(_jiggleController.value * math.pi * 5) *
                  0.025 *
                  (1 - _jiggleController.value);

        return Transform.translate(
          key: ValueKey('potion-bottle-jiggle-${widget.jiggleCount}'),
          offset: Offset(jiggleOffset, 0),
          child: Transform.rotate(
            angle: jiggleRotation,
            child: Semantics(
              button: true,
              label: widget.isFull
                  ? 'Potion bottle, ready to drink'
                  : 'Potion bottle, not full yet',
              child: GestureDetector(
                key: const ValueKey('potion-bottle-tap-target'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: TweenAnimationBuilder<double>(
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
                                        heightFactor: animatedProgress.clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        widthFactor: 1,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            DecoratedBox(
                                              key: const ValueKey(
                                                'potion-liquid-base',
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    blend.baseTop,
                                                    blend.baseMid,
                                                    blend.baseBottom,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                            ),
                                            for (final layer in blend.layers)
                                              _PotionLiquidBand(
                                                layer: layer,
                                                shimmerProgress:
                                                    widget.disableAnimations
                                                    ? 0.0
                                                    : _loopController.value,
                                              ),
                                            Positioned.fill(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(
                                                        alpha: 0.20,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0,
                                                      ),
                                                    ],
                                                    stops: const [
                                                      0,
                                                      0.22,
                                                      0.52,
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (!widget.disableAnimations)
                                              Align(
                                                alignment: Alignment(
                                                  -0.2,
                                                  1 -
                                                      (_loopController.value *
                                                          2),
                                                ),
                                                child: FractionallySizedBox(
                                                  widthFactor: 1,
                                                  heightFactor: 0.3,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0,
                                                              ),
                                                          blend.highlightColor
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.22,
                                                              ),
                                                          blend.highlightColor
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0,
                                                              ),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (!widget.disableAnimations)
                                              ..._bubbleLayers(
                                                animatedProgress,
                                              ),
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
                                              Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                              Colors.white.withValues(alpha: 0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                                  outlineColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
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
                ),
              ),
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

class _PotionLiquidBand extends StatelessWidget {
  const _PotionLiquidBand({required this.layer, required this.shimmerProgress});

  final _PotionBlendLayer layer;
  final double shimmerProgress;

  @override
  Widget build(BuildContext context) {
    final verticalDrift = (shimmerProgress - 0.5) * layer.drift;

    return Align(
      alignment: Alignment(
        layer.alignment.x,
        layer.alignment.y + verticalDrift,
      ),
      child: Transform.rotate(
        angle: layer.rotation,
        child: FractionallySizedBox(
          widthFactor: layer.widthFactor,
          heightFactor: layer.heightFactor,
          child: DecoratedBox(
            key: ValueKey('potion-band-${layer.id}'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  layer.color.withValues(alpha: 0),
                  layer.color.withValues(alpha: layer.opacity * 0.42),
                  Colors.white.withValues(alpha: layer.opacity * 0.14),
                  layer.color.withValues(alpha: layer.opacity * 0.32),
                  layer.color.withValues(alpha: 0),
                ],
                stops: const [0, 0.18, 0.5, 0.82, 1],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
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

class _PotionBlendData {
  const _PotionBlendData({
    required this.baseTop,
    required this.baseMid,
    required this.baseBottom,
    required this.highlightColor,
    required this.layers,
  });

  final Color baseTop;
  final Color baseMid;
  final Color baseBottom;
  final Color highlightColor;
  final List<_PotionBlendLayer> layers;
}

class _PotionBlendLayer {
  const _PotionBlendLayer({
    required this.id,
    required this.color,
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.rotation,
    required this.opacity,
    required this.drift,
  });

  final String id;
  final Color color;
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final double rotation;
  final double opacity;
  final double drift;
}

_PotionBlendData _resolvePotionBlend(
  List<TaskCategory> categories,
  ThemeData theme,
) {
  final affinityCounts = <CharacterStat, int>{};
  for (final category in categories) {
    final stat = CharacterStat.fromTaskCategory(category);
    affinityCounts.update(stat, (value) => value + 1, ifAbsent: () => 1);
  }

  final entries = affinityCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (entries.isEmpty) {
    return _PotionBlendData(
      baseTop: const Color(0xFFE7F6F0),
      baseMid: const Color(0xFFC7E4D9),
      baseBottom: theme.colorScheme.primary.withValues(alpha: 0.70),
      highlightColor: Colors.white,
      layers: const [],
    );
  }

  final totalWeight = entries.fold<int>(0, (sum, entry) => sum + entry.value);
  final weightedColors = [
    for (final entry in entries)
      _WeightedColor(
        color: _statPotionColor(entry.key),
        weight: entry.value / totalWeight,
      ),
  ];
  final mixedColor = _mixWeightedColors(weightedColors);
  final dominantColor = weightedColors.first.color;

  const layerSpecs = [
    (
      alignment: Alignment(-0.28, -0.58),
      widthFactor: 1.22,
      heightFactor: 0.30,
      rotation: -0.22,
      drift: 0.10,
    ),
    (
      alignment: Alignment(0.24, -0.08),
      widthFactor: 1.10,
      heightFactor: 0.24,
      rotation: 0.16,
      drift: 0.08,
    ),
    (
      alignment: Alignment(-0.18, 0.32),
      widthFactor: 1.18,
      heightFactor: 0.22,
      rotation: 0.22,
      drift: 0.06,
    ),
    (
      alignment: Alignment(0.18, 0.56),
      widthFactor: 1.08,
      heightFactor: 0.20,
      rotation: -0.12,
      drift: 0.05,
    ),
  ];

  final layers = <_PotionBlendLayer>[
    for (var index = 0; index < weightedColors.length; index += 1)
      _PotionBlendLayer(
        id: entries[index].key.name,
        color: weightedColors[index].color,
        alignment: layerSpecs[index].alignment,
        widthFactor: layerSpecs[index].widthFactor,
        heightFactor: layerSpecs[index].heightFactor,
        rotation: layerSpecs[index].rotation,
        opacity: 0.78 - (index * 0.10),
        drift: layerSpecs[index].drift,
      ),
  ];

  return _PotionBlendData(
    baseTop: Color.lerp(mixedColor, Colors.white, 0.32)!,
    baseMid: Color.lerp(mixedColor, dominantColor, 0.26)!,
    baseBottom: Color.lerp(
      Color.lerp(mixedColor, dominantColor, 0.45)!,
      const Color(0xFF183553),
      0.14,
    )!,
    highlightColor: Color.lerp(dominantColor, Colors.white, 0.38)!,
    layers: layers,
  );
}

class _WeightedColor {
  const _WeightedColor({required this.color, required this.weight});

  final Color color;
  final double weight;
}

Color _mixWeightedColors(List<_WeightedColor> colors) {
  if (colors.isEmpty) {
    return Colors.transparent;
  }

  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var alpha = 0.0;

  for (final entry in colors) {
    red += entry.color.r * entry.weight;
    green += entry.color.g * entry.weight;
    blue += entry.color.b * entry.weight;
    alpha += entry.color.a * entry.weight;
  }

  return Color.fromARGB(
    (alpha.clamp(0.0, 1.0) * 255).round(),
    (red.clamp(0.0, 1.0) * 255).round(),
    (green.clamp(0.0, 1.0) * 255).round(),
    (blue.clamp(0.0, 1.0) * 255).round(),
  );
}

Color _statPotionColor(CharacterStat stat) {
  return switch (stat) {
    CharacterStat.strength => const Color(0xFFD05A4E),
    CharacterStat.vitality => const Color(0xFFC88944),
    CharacterStat.wisdom => const Color(0xFF4878D9),
    CharacterStat.mindfulness => const Color(0xFF4F9770),
  };
}

Color _categoryColor(TaskCategory category) {
  return switch (category) {
    TaskCategory.fitness => const Color(0xFFD05A4E),
    TaskCategory.home => const Color(0xFFC88944),
    TaskCategory.study => const Color(0xFF4878D9),
    TaskCategory.work => const Color(0xFF4168C8),
    TaskCategory.hobby => const Color(0xFF4F9770),
  };
}
