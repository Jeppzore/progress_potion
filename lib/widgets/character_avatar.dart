import 'dart:math' as math;

import 'package:flutter/material.dart';

class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    required this.celebrationCount,
    this.size = const Size(150, 180),
  });

  final int celebrationCount;
  final Size size;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _celebrationController;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
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
    if (widget.celebrationCount != oldWidget.celebrationCount &&
        !_animationsDisabled) {
      _celebrationController
        ..stop()
        ..forward(from: 0);
    }
  }

  void _syncAnimationState() {
    if (_animationsDisabled) {
      _idleController.stop();
      _celebrationController.stop();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _celebrationController]),
      builder: (context, child) {
        final idleOffset = _animationsDisabled
            ? 0.0
            : (_idleController.value - 0.5) * 6;
        final celebrationArc = _animationsDisabled
            ? 0.0
            : math.sin(_celebrationController.value * math.pi) * 14;
        final celebrationRotate = _animationsDisabled
            ? 0.0
            : math.sin(_celebrationController.value * math.pi) * 0.04;

        return SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 8,
                child: Container(
                  width: widget.size.width * 0.46,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, idleOffset - celebrationArc),
                child: Transform.rotate(angle: celebrationRotate, child: child),
              ),
              if (!_animationsDisabled && _celebrationController.value > 0)
                ..._sparkles(theme),
            ],
          ),
        );
      },
      child: _AvatarFigure(size: widget.size),
    );
  }

  List<Widget> _sparkles(ThemeData theme) {
    final opacity = Curves.easeOut.transform(
      1 - _celebrationController.value.clamp(0.0, 1.0),
    );
    final progress = _celebrationController.value;

    return [
      Positioned(
        top: 24 - (progress * 10),
        left: 18,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.secondary,
            size: 16,
          ),
        ),
      ),
      Positioned(
        top: 8 - (progress * 8),
        right: 12,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.primary,
            size: 14,
          ),
        ),
      ),
      Positioned(
        top: 52 - (progress * 12),
        right: 26,
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
  const _AvatarFigure({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 18,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF7C4A4), Color(0xFFEEA77E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3C2D4E),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                          bottom: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(top: 30, left: 18, child: _FaceDot()),
                  const Positioned(top: 30, right: 18, child: _FaceDot()),
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B4E3C),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 74,
            child: Container(
              width: 20,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFF2B392),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 86,
            child: Container(
              width: 86,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C6FFF), Color(0xFF2849B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 92,
            left: 12,
            child: Transform.rotate(
              angle: -0.22,
              child: const _Limb(
                width: 20,
                height: 64,
                color: Color(0xFFF0B08A),
              ),
            ),
          ),
          Positioned(
            top: 92,
            right: 12,
            child: Transform.rotate(
              angle: 0.26,
              child: const _Limb(
                width: 20,
                height: 64,
                color: Color(0xFFF0B08A),
              ),
            ),
          ),
          const Positioned(
            bottom: 8,
            left: 40,
            child: _Limb(width: 20, height: 74, color: Color(0xFF26304C)),
          ),
          const Positioned(
            bottom: 8,
            right: 40,
            child: _Limb(width: 20, height: 74, color: Color(0xFF26304C)),
          ),
          Positioned(
            bottom: 0,
            left: 32,
            child: Container(
              width: 34,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF17213A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 32,
            child: Container(
              width: 34,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF17213A),
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
  const _FaceDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF3D2B24),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Limb extends StatelessWidget {
  const _Limb({required this.width, required this.height, required this.color});

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
