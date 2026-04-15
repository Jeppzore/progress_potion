import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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

class _CharacterAvatarState extends State<CharacterAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _celebrationController;
  late final AnimationController _waveController;
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
    _waveController = AnimationController(
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

    if (celebrationChanged || interactionChanged) {
      _celebrationController
        ..stop()
        ..forward(from: 0);
    }

    if (interactionChanged) {
      _waveController
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
      _waveController.stop();
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
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleController,
        _celebrationController,
        _waveController,
      ]),
      builder: (context, _) {
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
        final waveSwing = _animationsDisabled
            ? 0.0
            : math.sin(_waveController.value * math.pi * 3.2) *
                  (1 - _waveController.value) *
                  0.75;
        final auraOpacity =
            (0.12 + (idlePhase * 0.05) + (celebrationBurst * 0.2)).clamp(
              0.0,
              0.34,
            );

        final figure = _AvatarFigure(
          size: widget.size,
          stats: widget.stats,
          idlePhase: idlePhase,
          waveSwing: waveSwing,
        );

        final tappableFigure = widget.onTap == null
            ? figure
            : Semantics(
                button: true,
                label: 'Potionkeeper companion',
                hint: 'Tap to encourage your companion',
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
                offset: Offset(0, idleFloat - celebrationLift),
                child: Transform.rotate(
                  angle: celebrationRotate,
                  child: tappableFigure,
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
    required this.idlePhase,
    required this.waveSwing,
  });

  final Size size;
  final CharacterStats stats;
  final double idlePhase;
  final double waveSwing;

  @override
  Widget build(BuildContext context) {
    final strengthLevel = _traitLevel(stats.strength, maxValue: 12);
    final vitalityPosture = _vitalityPosture(stats.vitality);
    final wisdomLevel = _traitLevel(stats.wisdom, maxValue: 10);
    final mindfulnessLevel = _traitLevel(stats.mindfulness, maxValue: 10);
    final seatedLevel = 1 - vitalityPosture;

    double sx(double value) => value * (size.width / 150);
    double sy(double value) => value * (size.height / 180);

    final headSize = sx(68 + (wisdomLevel * 6) + (vitalityPosture * 2));
    final headTop = sy(42 - (vitalityPosture * 26));
    final neckTop = headTop + sy(56);
    final neckHeight = sy(10 + (vitalityPosture * 8));
    final torsoTop = sy(96 - (vitalityPosture * 26));
    final torsoWidth = sx(76 + (strengthLevel * 16) + (vitalityPosture * 6));
    final torsoHeight = sy(
      58 + (vitalityPosture * 18) + (strengthLevel * 8) + (idlePhase * 1.5),
    );
    final armWidth = sx(16 + (strengthLevel * 5));
    final armHeight = sy(44 + (vitalityPosture * 18) + (strengthLevel * 10));
    final armTop = torsoTop + sy(8);
    final armInset = sx(14 - (strengthLevel * 2) - (vitalityPosture * 1.5));
    final legTop = torsoTop + torsoHeight - sy(10);
    final legWidth = sx(18 + (strengthLevel * 4));
    final legHeight = sy(42 + (vitalityPosture * 40));
    final legInset = sx(40 - (vitalityPosture * 7));
    final footWidth = sx(28 + (vitalityPosture * 8));
    final footInset = sx(27 - (vitalityPosture * 4));
    final footHeight = sy(12);
    final seatTop = legTop - sy(10);
    final seatOpacity = (0.55 * seatedLevel).clamp(0.0, 0.55);
    final smileSize = Size(
      sx(17 + (mindfulnessLevel * 14)),
      sy(6 + (mindfulnessLevel * 5)),
    );
    final leftArmAngle =
        lerpDouble(-0.95, -0.18, vitalityPosture)! + (mindfulnessLevel * 0.08);
    final rightArmAngle =
        lerpDouble(0.95, 0.18, vitalityPosture)! -
        (mindfulnessLevel * 0.05) -
        waveSwing;
    final beardHeight = wisdomLevel <= 0.14 ? 0.0 : sy(8 + (wisdomLevel * 12));
    final beardTop = headTop + (headSize * 0.78);
    final mouthTop = headTop + (headSize * 0.60);
    final browTop = headTop + (headSize * 0.31);
    final browInset = sx(16);
    final eyeTop = headTop + (headSize * 0.44);
    final eyeInset = sx(19);
    final hairHeight = sy(15 + (wisdomLevel * 4));
    final hairInset = sx(12);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (seatOpacity > 0.02)
            Positioned(
              key: const ValueKey('avatar-seat'),
              top: seatTop,
              child: Opacity(
                opacity: seatOpacity,
                child: Container(
                  width: sx(92),
                  height: sy(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB88D67),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          Positioned(
            top: headTop,
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
                    top: browTop,
                    left: browInset,
                    child: _Brow(
                      key: const ValueKey('avatar-left-brow'),
                      angle: -0.16 + (mindfulnessLevel * 0.08),
                      width: sx(14 + (wisdomLevel * 4)),
                    ),
                  ),
                  Positioned(
                    top: browTop,
                    right: browInset,
                    child: _Brow(
                      key: const ValueKey('avatar-right-brow'),
                      angle: 0.16 - (mindfulnessLevel * 0.08),
                      width: sx(14 + (wisdomLevel * 4)),
                    ),
                  ),
                  Positioned(
                    top: eyeTop,
                    left: eyeInset,
                    child: _FaceDot(smileLevel: mindfulnessLevel, size: sx(8)),
                  ),
                  Positioned(
                    top: eyeTop,
                    right: eyeInset,
                    child: _FaceDot(smileLevel: mindfulnessLevel, size: sx(8)),
                  ),
                  Positioned(
                    top: headTop + (headSize * 0.50) - headTop,
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
                    top: mouthTop - headTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        key: const ValueKey('avatar-mouth'),
                        width: smileSize.width,
                        height: smileSize.height,
                        child: CustomPaint(
                          painter: _MouthPainter(smileLevel: mindfulnessLevel),
                        ),
                      ),
                    ),
                  ),
                  if (beardHeight > 0)
                    Positioned(
                      top: beardTop - headTop,
                      left: sx(15 - (wisdomLevel * 3)),
                      right: sx(15 - (wisdomLevel * 3)),
                      child: Container(
                        key: const ValueKey('avatar-beard'),
                        height: beardHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(
                                0xFF765344,
                              ).withValues(alpha: 0.82 + (wisdomLevel * 0.10)),
                              const Color(
                                0xFF4B362C,
                              ).withValues(alpha: 0.92 + (wisdomLevel * 0.06)),
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
          Positioned(
            top: neckTop,
            child: Container(
              width: sx(20),
              height: neckHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF1B493),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(sx(10)),
                ),
              ),
            ),
          ),
          Positioned(
            top: torsoTop,
            child: Container(
              key: const ValueKey('avatar-torso'),
              width: torsoWidth,
              height: torsoHeight,
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
          Positioned(
            top: armTop,
            left: armInset,
            child: Transform.rotate(
              angle: leftArmAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-left-arm'),
                width: armWidth,
                height: armHeight,
                color: const Color(0xFFF2B28C),
              ),
            ),
          ),
          Positioned(
            top: armTop,
            right: armInset,
            child: Transform.rotate(
              angle: rightArmAngle,
              alignment: Alignment.topCenter,
              child: _Limb(
                key: const ValueKey('avatar-right-arm'),
                width: armWidth,
                height: armHeight,
                color: const Color(0xFFF2B28C),
              ),
            ),
          ),
          Positioned(
            top: legTop,
            left: legInset,
            child: _Limb(
              key: const ValueKey('avatar-left-leg'),
              width: legWidth,
              height: legHeight,
              color: const Color(0xFF26304C),
            ),
          ),
          Positioned(
            top: legTop,
            right: legInset,
            child: _Limb(
              key: const ValueKey('avatar-right-leg'),
              width: legWidth,
              height: legHeight,
              color: const Color(0xFF26304C),
            ),
          ),
          Positioned(
            bottom: 0,
            left: footInset,
            child: Container(
              key: const ValueKey('avatar-left-foot'),
              width: footWidth,
              height: footHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF16213A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: footInset,
            child: Container(
              key: const ValueKey('avatar-right-foot'),
              width: footWidth,
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

double _vitalityPosture(int vitality) {
  if (vitality <= 0) {
    return 0;
  }
  if (vitality >= 100) {
    return 1;
  }
  if (vitality <= 24) {
    return _segmentProgress(
      vitality,
      startValue: 0,
      endValue: 24,
      startOutput: 0,
      endOutput: 0.18,
      curve: Curves.easeOutCubic,
    );
  }
  if (vitality <= 59) {
    return _segmentProgress(
      vitality,
      startValue: 25,
      endValue: 59,
      startOutput: 0.18,
      endOutput: 0.58,
      curve: Curves.easeInOutCubic,
    );
  }
  return _segmentProgress(
    vitality,
    startValue: 60,
    endValue: 99,
    startOutput: 0.58,
    endOutput: 0.97,
    curve: Curves.easeOutCubic,
  );
}

double _segmentProgress(
  int value, {
  required int startValue,
  required int endValue,
  required double startOutput,
  required double endOutput,
  required Curve curve,
}) {
  final span = endValue - startValue;
  if (span <= 0) {
    return endOutput;
  }
  final rawT = ((value - startValue) / span).clamp(0.0, 1.0);
  final curvedT = curve.transform(rawT);
  return lerpDouble(startOutput, endOutput, curvedT)!;
}
