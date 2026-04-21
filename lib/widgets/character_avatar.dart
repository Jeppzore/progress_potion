import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:progress_potion/models/character_stats.dart';

class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    required this.stats,
    required this.celebrationCount,
    this.interactionCount = 0,
    this.onTap,
    this.size = const Size(150, 180),
  });

  final CharacterStats stats;
  final int celebrationCount;
  final int interactionCount;
  final VoidCallback? onTap;
  final Size size;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

enum _AvatarPose {
  resting('resting', 'resting', 'Tap to wake and stretch your companion'),
  bending('bending', 'finding balance', 'Tap for a balancing wobble'),
  standingTall('standing-tall', 'standing tall', 'Tap for a proud hop');

  const _AvatarPose(this.keyName, this.semanticsLabel, this.tapHint);

  final String keyName;
  final String semanticsLabel;
  final String tapHint;
}

class _CharacterAvatarState extends State<CharacterAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _celebrationController;
  late final AnimationController _reactionController;
  bool _animationsDisabled = false;
  int _reducedMotionPulseToken = 0;
  bool _showReducedMotionPulse = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsDisabled = MediaQuery.of(context).disableAnimations;
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant CharacterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final celebrationChanged =
        widget.celebrationCount != oldWidget.celebrationCount;
    final interactionChanged =
        widget.interactionCount != oldWidget.interactionCount;

    if (_animationsDisabled) {
      if (celebrationChanged || interactionChanged) {
        _triggerReducedMotionPulse();
      }
      return;
    }

    if (celebrationChanged) {
      _celebrationController
        ..stop()
        ..forward(from: 0);
    }

    if (interactionChanged) {
      _reactionController
        ..stop()
        ..forward(from: 0);
    }
  }

  void _triggerReducedMotionPulse() {
    final pulseToken = ++_reducedMotionPulseToken;
    setState(() {
      _showReducedMotionPulse = true;
    });

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || pulseToken != _reducedMotionPulseToken) {
          return;
        }
        setState(() {
          _showReducedMotionPulse = false;
        });
      }),
    );
  }

  void _syncAnimationState() {
    if (_animationsDisabled) {
      _idleController.stop();
      _celebrationController.stop();
      _reactionController.stop();
      return;
    }

    if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _celebrationController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleController,
        _celebrationController,
        _reactionController,
      ]),
      builder: (context, _) {
        final pose = _poseForVitality(widget.stats.vitality);
        final idlePhase = _animationsDisabled
            ? 0.5
            : Curves.easeInOut.transform(_idleController.value);
        final idleFloat = _animationsDisabled
            ? 0.0
            : math.sin(_idleController.value * math.pi * 2) * 2.2;
        final celebrationBurst = _animationsDisabled
            ? 0.0
            : math.sin(_celebrationController.value * math.pi);
        final celebrationLift = celebrationBurst * 10;
        final celebrationRotate = celebrationBurst * 0.028;
        final reactionProgress = _animationsDisabled
            ? 0.0
            : _reactionController.value.clamp(0.0, 1.0);
        final reactionBurst = math.sin(reactionProgress * math.pi);
        final reactionWobble =
            math.sin(reactionProgress * math.pi * 4) * (1 - reactionProgress);
        final reactionLift = switch (pose) {
          _AvatarPose.resting => reactionBurst * 4,
          _AvatarPose.bending => reactionBurst * 2,
          _AvatarPose.standingTall => reactionBurst * 12,
        };
        final reactionOffsetX = pose == _AvatarPose.bending
            ? reactionWobble * 6
            : 0.0;
        final reactionRotate = switch (pose) {
          _AvatarPose.resting => -reactionBurst * 0.035,
          _AvatarPose.bending => reactionWobble * 0.08,
          _AvatarPose.standingTall => reactionWobble * 0.03,
        };
        final auraOpacity =
            (0.12 + (idlePhase * 0.05) + (celebrationBurst * 0.2)).clamp(
              0.0,
              0.34,
            );

        final figure = _AvatarFigure(
          size: widget.size,
          stats: widget.stats,
          pose: pose,
          idlePhase: idlePhase,
          reactionProgress: reactionProgress,
        );

        final tappableFigure = widget.onTap == null
            ? figure
            : Semantics(
                button: true,
                label: 'Potionkeeper companion, ${pose.semanticsLabel}',
                hint: pose.tapHint,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('avatar-tap-target'),
                    borderRadius: BorderRadius.circular(28),
                    onTap: widget.onTap,
                    child: figure,
                  ),
                ),
              );
        final reactingFigure =
            !_animationsDisabled && _reactionController.value > 0
            ? KeyedSubtree(
                key: ValueKey('avatar-${pose.keyName}-reaction'),
                child: tappableFigure,
              )
            : tappableFigure;

        return SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: widget.size.height * 0.1,
                child: Opacity(
                  opacity: auraOpacity,
                  child: Container(
                    width: widget.size.width * 0.7,
                    height: widget.size.height * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.secondary.withValues(alpha: 0.28),
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.54, 1],
                      ),
                    ),
                  ),
                ),
              ),
              if (_animationsDisabled && _showReducedMotionPulse)
                Positioned(
                  key: const ValueKey('avatar-reduced-motion-pulse'),
                  bottom: widget.size.height * 0.16,
                  child: Container(
                    width: widget.size.width * 0.8,
                    height: widget.size.height * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.28,
                        ),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 6,
                child: Container(
                  width: widget.size.width * 0.5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(
                  reactionOffsetX,
                  idleFloat - celebrationLift - reactionLift,
                ),
                child: Transform.rotate(
                  angle: celebrationRotate + reactionRotate,
                  child: reactingFigure,
                ),
              ),
              if (!_animationsDisabled && _celebrationController.value > 0)
                ..._sparkles(theme),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _sparkles(ThemeData theme) {
    final opacity = Curves.easeOut.transform(
      1 - _celebrationController.value.clamp(0.0, 1.0),
    );
    final progress = _celebrationController.value;
    final rise = progress * 18;

    return [
      Positioned(
        key: const ValueKey('avatar-sparkle-0'),
        top: 18 - rise,
        left: 12,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: theme.colorScheme.secondary,
            size: 16,
          ),
        ),
      ),
      Positioned(
        key: const ValueKey('avatar-sparkle-1'),
        top: 6 - (rise * 0.8),
        right: 14,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: theme.colorScheme.primary,
            size: 14,
          ),
        ),
      ),
      Positioned(
        key: const ValueKey('avatar-sparkle-2'),
        top: 48 - (rise * 1.1),
        right: 24,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.star_rounded,
            color: theme.colorScheme.tertiary,
            size: 14,
          ),
        ),
      ),
    ];
  }
}

class _AvatarFigure extends StatelessWidget {
  const _AvatarFigure({
    required this.size,
    required this.stats,
    required this.pose,
    required this.idlePhase,
    required this.reactionProgress,
  });

  final Size size;
  final CharacterStats stats;
  final _AvatarPose pose;
  final double idlePhase;
  final double reactionProgress;

  @override
  Widget build(BuildContext context) {
    final strengthLevel = _traitLevel(stats.strength, maxValue: 12);
    final wisdomLevel = _traitLevel(stats.wisdom, maxValue: 10);
    final mindfulnessLevel = _traitLevel(stats.mindfulness, maxValue: 10);
    final reactionBurst = math.sin(reactionProgress * math.pi);
    final reactionWobble =
        math.sin(reactionProgress * math.pi * 4) * (1 - reactionProgress);

    double sx(double value) => value * (size.width / 150);
    double sy(double value) => value * (size.height / 180);

    final headSize = sx(68 + (wisdomLevel * 6));
    final armWidth = sx(16 + (strengthLevel * 5));
    final legWidth = sx(18 + (strengthLevel * 4));
    final footHeight = sy(12);
    final smileSize = Size(
      sx(17 + (mindfulnessLevel * 14)),
      sy(6 + (mindfulnessLevel * 5)),
    );
    final poseMetrics = _PoseMetrics.forPose(
      pose: pose,
      sx: sx,
      sy: sy,
      strengthLevel: strengthLevel,
      mindfulnessLevel: mindfulnessLevel,
      idlePhase: idlePhase,
      reactionBurst: reactionBurst,
      reactionWobble: reactionWobble,
    );
    final beardHeight = wisdomLevel <= 0.14 ? 0.0 : sy(8 + (wisdomLevel * 12));
    final beardTop = poseMetrics.headTop + (headSize * 0.78);
    final mouthTop = poseMetrics.headTop + (headSize * 0.60);
    final browTop = poseMetrics.headTop + (headSize * 0.31);
    final browInset = sx(16);
    final eyeTop = poseMetrics.headTop + (headSize * 0.44);
    final eyeInset = sx(19);
    final hairHeight = sy(15 + (wisdomLevel * 4));
    final hairInset = sx(12);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (poseMetrics.platformOpacity > 0)
            Positioned(
              key: const ValueKey('avatar-seat'),
              top: poseMetrics.platformTop,
              child: Opacity(
                opacity: poseMetrics.platformOpacity,
                child: Container(
                  width: poseMetrics.platformWidth,
                  height: sy(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB88D67),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          Positioned(
            key: ValueKey('avatar-pose-${pose.keyName}'),
            bottom: 0,
            child: const SizedBox.shrink(),
          ),
          Positioned(
            top: poseMetrics.headTop,
            left: poseMetrics.headLeft,
            child: Transform.rotate(
              angle: poseMetrics.headAngle,
              child: Container(
                key: const ValueKey('avatar-head'),
                width: headSize,
                height: headSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8CFB6), Color(0xFFEDA67E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B4E3C).withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: sy(6),
                      left: hairInset,
                      right: hairInset,
                      child: Container(
                        key: const ValueKey('avatar-hairline'),
                        height: hairHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3C2D4E), Color(0xFF5E456D)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(sx(24)),
                            bottom: Radius.circular(sx(14)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: browTop - poseMetrics.headTop,
                      left: browInset,
                      child: _Brow(
                        key: const ValueKey('avatar-left-brow'),
                        angle: -0.16 + (mindfulnessLevel * 0.08),
                        width: sx(14 + (wisdomLevel * 4)),
                      ),
                    ),
                    Positioned(
                      top: browTop - poseMetrics.headTop,
                      right: browInset,
                      child: _Brow(
                        key: const ValueKey('avatar-right-brow'),
                        angle: 0.16 - (mindfulnessLevel * 0.08),
                        width: sx(14 + (wisdomLevel * 4)),
                      ),
                    ),
                    Positioned(
                      top: eyeTop - poseMetrics.headTop,
                      left: eyeInset,
                      child: _FaceDot(
                        smileLevel: mindfulnessLevel,
                        size: sx(8),
                      ),
                    ),
                    Positioned(
                      top: eyeTop - poseMetrics.headTop,
                      right: eyeInset,
                      child: _FaceDot(
                        smileLevel: mindfulnessLevel,
                        size: sx(8),
                      ),
                    ),
                    Positioned(
                      top: headSize * 0.50,
                      left: (headSize / 2) - sx(2),
                      child: Container(
                        width: sx(4),
                        height: sy(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC67D5F).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (mindfulnessLevel > 0.12)
                      Positioned(
                        top: headSize * 0.56,
                        left: sx(10),
                        child: _CheekGlow(
                          opacity: 0.10 + (mindfulnessLevel * 0.12),
                          size: sx(10),
                        ),
                      ),
                    if (mindfulnessLevel > 0.12)
                      Positioned(
                        top: headSize * 0.56,
                        right: sx(10),
                        child: _CheekGlow(
                          opacity: 0.10 + (mindfulnessLevel * 0.12),
                          size: sx(10),
                        ),
                      ),
                    Positioned(
                      top: mouthTop - poseMetrics.headTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          key: const ValueKey('avatar-mouth'),
                          width: smileSize.width,
                          height: smileSize.height,
                          child: CustomPaint(
                            painter: _MouthPainter(
                              smileLevel: mindfulnessLevel,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (beardHeight > 0)
                      Positioned(
                        top: beardTop - poseMetrics.headTop,
                        left: sx(15 - (wisdomLevel * 3)),
                        right: sx(15 - (wisdomLevel * 3)),
                        child: Container(
                          key: const ValueKey('avatar-beard'),
                          height: beardHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF765344).withValues(
                                  alpha: 0.82 + (wisdomLevel * 0.10),
                                ),
                                const Color(0xFF4B362C).withValues(
                                  alpha: 0.92 + (wisdomLevel * 0.06),
                                ),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(sx(7)),
                              bottom: Radius.circular(sx(20)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.neckTop,
            left: poseMetrics.neckLeft,
            child: Transform.rotate(
              angle: poseMetrics.torsoAngle,
              child: Container(
                width: sx(20),
                height: poseMetrics.neckHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1B493),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(sx(10)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.torsoTop,
            left: poseMetrics.torsoLeft,
            child: Transform.rotate(
              angle: poseMetrics.torsoAngle,
              child: Container(
                key: const ValueKey('avatar-torso'),
                width: poseMetrics.torsoWidth,
                height: poseMetrics.torsoHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sx(28)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF446AFF), Color(0xFF2747B4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2747B4).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.armTop,
            left: poseMetrics.leftArmLeft,
            child: Transform.rotate(
              angle: poseMetrics.leftArmAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-left-arm'),
                width: armWidth,
                height: poseMetrics.armHeight,
                color: const Color(0xFFF2B28C),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.armTop,
            right: poseMetrics.rightArmRight,
            child: Transform.rotate(
              angle: poseMetrics.rightArmAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-right-arm'),
                width: armWidth,
                height: poseMetrics.armHeight,
                color: const Color(0xFFF2B28C),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.legTop,
            left: poseMetrics.leftLegLeft,
            child: Transform.rotate(
              angle: poseMetrics.leftLegAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-left-leg'),
                width: legWidth,
                height: poseMetrics.legHeight,
                color: const Color(0xFF26304C),
              ),
            ),
          ),
          Positioned(
            top: poseMetrics.legTop,
            right: poseMetrics.rightLegRight,
            child: Transform.rotate(
              angle: poseMetrics.rightLegAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-right-leg'),
                width: legWidth,
                height: poseMetrics.legHeight,
                color: const Color(0xFF26304C),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: poseMetrics.leftFootLeft,
            child: Container(
              key: const ValueKey('avatar-left-foot'),
              width: poseMetrics.footWidth,
              height: footHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF16213A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: poseMetrics.rightFootRight,
            child: Container(
              key: const ValueKey('avatar-right-foot'),
              width: poseMetrics.footWidth,
              height: footHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF16213A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseMetrics {
  const _PoseMetrics({
    required this.headTop,
    required this.headLeft,
    required this.headAngle,
    required this.neckTop,
    required this.neckLeft,
    required this.neckHeight,
    required this.torsoTop,
    required this.torsoLeft,
    required this.torsoWidth,
    required this.torsoHeight,
    required this.torsoAngle,
    required this.armTop,
    required this.leftArmLeft,
    required this.rightArmRight,
    required this.armHeight,
    required this.leftArmAngle,
    required this.rightArmAngle,
    required this.legTop,
    required this.leftLegLeft,
    required this.rightLegRight,
    required this.legHeight,
    required this.leftLegAngle,
    required this.rightLegAngle,
    required this.leftFootLeft,
    required this.rightFootRight,
    required this.footWidth,
    required this.platformTop,
    required this.platformWidth,
    required this.platformOpacity,
  });

  final double headTop;
  final double headLeft;
  final double headAngle;
  final double neckTop;
  final double neckLeft;
  final double neckHeight;
  final double torsoTop;
  final double torsoLeft;
  final double torsoWidth;
  final double torsoHeight;
  final double torsoAngle;
  final double armTop;
  final double leftArmLeft;
  final double rightArmRight;
  final double armHeight;
  final double leftArmAngle;
  final double rightArmAngle;
  final double legTop;
  final double leftLegLeft;
  final double rightLegRight;
  final double legHeight;
  final double leftLegAngle;
  final double rightLegAngle;
  final double leftFootLeft;
  final double rightFootRight;
  final double footWidth;
  final double platformTop;
  final double platformWidth;
  final double platformOpacity;

  factory _PoseMetrics.forPose({
    required _AvatarPose pose,
    required double Function(double value) sx,
    required double Function(double value) sy,
    required double strengthLevel,
    required double mindfulnessLevel,
    required double idlePhase,
    required double reactionBurst,
    required double reactionWobble,
  }) {
    return switch (pose) {
      _AvatarPose.resting => _PoseMetrics(
        headTop: sy(55 - (reactionBurst * 5)),
        headLeft: sx(34),
        headAngle: -0.16 + (reactionBurst * 0.08),
        neckTop: sy(106 - (reactionBurst * 5)),
        neckLeft: sx(66),
        neckHeight: sy(9 + (reactionBurst * 4)),
        torsoTop: sy(109 - (reactionBurst * 7)),
        torsoLeft: sx(36),
        torsoWidth: sx(78 + (strengthLevel * 14) + (reactionBurst * 4)),
        torsoHeight: sy(
          46 + (strengthLevel * 7) + (idlePhase * 1.2) + (reactionBurst * 6),
        ),
        torsoAngle: -0.10 + (reactionBurst * 0.06),
        armTop: sy(116 - (reactionBurst * 9)),
        leftArmLeft: sx(21 - (strengthLevel * 2)),
        rightArmRight: sx(18 - (strengthLevel * 2)),
        armHeight: sy(36 + (strengthLevel * 8) + (reactionBurst * 15)),
        leftArmAngle: -1.05 - (reactionBurst * 0.38),
        rightArmAngle:
            1.02 + (reactionBurst * 0.34) - (mindfulnessLevel * 0.04),
        legTop: sy(145 - (reactionBurst * 3)),
        leftLegLeft: sx(31),
        rightLegRight: sx(31),
        legHeight: sy(34 + (strengthLevel * 5)),
        leftLegAngle: -0.86,
        rightLegAngle: 0.86,
        leftFootLeft: sx(19),
        rightFootRight: sx(19),
        footWidth: sx(32),
        platformTop: sy(151),
        platformWidth: sx(114),
        platformOpacity: 0.58,
      ),
      _AvatarPose.bending => _PoseMetrics(
        headTop: sy(35 + (reactionWobble * 1.4)),
        headLeft: sx(29 + (reactionWobble * 2)),
        headAngle: -0.12 + (reactionWobble * 0.04),
        neckTop: sy(91),
        neckLeft: sx(62),
        neckHeight: sy(13),
        torsoTop: sy(90),
        torsoLeft: sx(36 + (reactionWobble * 2)),
        torsoWidth: sx(80 + (strengthLevel * 16)),
        torsoHeight: sy(61 + (strengthLevel * 8) + (idlePhase * 1.3)),
        torsoAngle: -0.22 + (reactionWobble * 0.07),
        armTop: sy(99),
        leftArmLeft: sx(15 - (strengthLevel * 2)),
        rightArmRight: sx(13 - (strengthLevel * 2)),
        armHeight: sy(54 + (strengthLevel * 9)),
        leftArmAngle: -0.64 - (reactionWobble * 0.15),
        rightArmAngle:
            0.62 + (reactionWobble * 0.18) - (mindfulnessLevel * 0.04),
        legTop: sy(136),
        leftLegLeft: sx(38),
        rightLegRight: sx(37),
        legHeight: sy(48 + (strengthLevel * 7)),
        leftLegAngle: -0.28,
        rightLegAngle: 0.30,
        leftFootLeft: sx(25),
        rightFootRight: sx(22),
        footWidth: sx(34),
        platformTop: 0,
        platformWidth: 0,
        platformOpacity: 0,
      ),
      _AvatarPose.standingTall => _PoseMetrics(
        headTop: sy(20 - (reactionBurst * 5)),
        headLeft: sx(41),
        headAngle: reactionWobble * 0.025,
        neckTop: sy(76 - (reactionBurst * 5)),
        neckLeft: sx(65),
        neckHeight: sy(18),
        torsoTop: sy(86 - (reactionBurst * 6)),
        torsoLeft: sx(33),
        torsoWidth: sx(86 + (strengthLevel * 16)),
        torsoHeight: sy(61 + (strengthLevel * 8) + (idlePhase * 1.4)),
        torsoAngle: reactionWobble * 0.025,
        armTop: sy(96 - (reactionBurst * 6)),
        leftArmLeft: sx(16 - (strengthLevel * 2)),
        rightArmRight: sx(16 - (strengthLevel * 2)),
        armHeight: sy(62 + (strengthLevel * 10)),
        leftArmAngle: -0.20 + (mindfulnessLevel * 0.05),
        rightArmAngle:
            0.18 - (reactionBurst * 1.12) - (mindfulnessLevel * 0.04),
        legTop: sy(139 - (reactionBurst * 5)),
        leftLegLeft: sx(44),
        rightLegRight: sx(44),
        legHeight: sy(50 + (strengthLevel * 9)),
        leftLegAngle: -0.04,
        rightLegAngle: 0.04,
        leftFootLeft: sx(31),
        rightFootRight: sx(31),
        footWidth: sx(38),
        platformTop: 0,
        platformWidth: 0,
        platformOpacity: 0,
      ),
    };
  }
}

class _FaceDot extends StatelessWidget {
  const _FaceDot({required this.smileLevel, required this.size});

  final double smileLevel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size - (smileLevel * (size * 0.25)),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2B24),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Limb extends StatelessWidget {
  const _Limb({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Brow extends StatelessWidget {
  const _Brow({super.key, required this.angle, required this.width});

  final double angle;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 3.5,
        decoration: BoxDecoration(
          color: const Color(0xFF4D372E),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CheekGlow extends StatelessWidget {
  const _CheekGlow({required this.opacity, required this.size});

  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4A18E).withValues(alpha: opacity),
      ),
    );
  }
}

class _MouthPainter extends CustomPainter {
  const _MouthPainter({required this.smileLevel});

  final double smileLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4E3C)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;

    final smileDepth = 1.1 + (smileLevel * (size.height - 1.6));
    final path = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width / 2,
        smileDepth,
        size.width,
        size.height * 0.42,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MouthPainter oldDelegate) {
    return oldDelegate.smileLevel != smileLevel;
  }
}

double _traitLevel(int value, {required int maxValue}) {
  return (value / maxValue).clamp(0.0, 1.0);
}

_AvatarPose _poseForVitality(int vitality) {
  if (vitality <= 24) {
    return _AvatarPose.resting;
  }
  if (vitality <= 59) {
    return _AvatarPose.bending;
  }
  return _AvatarPose.standingTall;
}
