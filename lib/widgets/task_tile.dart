import 'package:flutter/material.dart';
import 'package:progress_potion/models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.isFavorite = false,
    this.isStarter = false,
    this.isCompleting = false,
    this.onComplete,
    this.onRemove,
    this.onFavorite,
    this.onStarter,
  });

  final Task task;
  final bool isFavorite;
  final bool isStarter;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onRemove;
  final VoidCallback? onFavorite;
  final VoidCallback? onStarter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final effectiveIsCompleted = task.isCompleted || isCompleting;
    final successColor = const Color(0xFF3C9A5F);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 420);
    final badgeColor = effectiveIsCompleted
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final cardColor = isCompleting
        ? const Color(0xFFE2F3E8)
        : task.isCompleted
        ? theme.colorScheme.surface
        : Colors.white.withValues(alpha: 0.92);
    final sideAccent = effectiveIsCompleted
        ? successColor
        : theme.colorScheme.secondary;

    return AnimatedSlide(
      key: ValueKey('task-tile-slide-${task.id}'),
      offset: isCompleting ? const Offset(0.18, 0) : Offset.zero,
      duration: duration,
      curve: Curves.easeInOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            if (isCompleting)
              BoxShadow(
                color: successColor.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Card(
          key: ValueKey('task-tile-card-${task.id}'),
          color: cardColor,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isCompleting
                    ? successColor.withValues(alpha: 0.40)
                    : theme.colorScheme.primary.withValues(alpha: 0.06),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: task.description.isEmpty ? 60 : 80,
                    decoration: BoxDecoration(
                      color: sideAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  color: effectiveIsCompleted
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: isCompleting ? 0.88 : 0.74,
                                        )
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                effectiveIsCompleted ? 'Completed' : 'Active',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Semantics(
                              label: 'Category ${task.category.displayName}',
                              child: _TaskSurfaceTag(
                                label: task.category.displayName,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                textColor: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isStarter)
                              _TaskSurfaceTag(
                                label: 'Starter',
                                color: theme.colorScheme.primaryContainer,
                                textColor: theme.colorScheme.onPrimaryContainer,
                              ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15.5,
                              color: effectiveIsCompleted
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: effectiveIsCompleted
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: successColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Done',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (onRemove != null)
                                      TextButton.icon(
                                        onPressed: onRemove,
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                        ),
                                        label: const Text('Remove'),
                                      ),
                                    if (isFavorite)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Favorited',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      )
                                    else if (onFavorite != null)
                                      TextButton.icon(
                                        onPressed: onFavorite,
                                        icon: const Icon(
                                          Icons.star_border_rounded,
                                        ),
                                        label: const Text('+ Favorite'),
                                      ),
                                    if (isStarter)
                                      _TaskInlineStatus(
                                        icon: Icons.restart_alt_rounded,
                                        label: 'Starter',
                                        color: theme.colorScheme.primary,
                                      )
                                    else if (onStarter != null)
                                      TextButton.icon(
                                        onPressed: onStarter,
                                        icon: const Icon(
                                          Icons.restart_alt_rounded,
                                        ),
                                        label: const Text('+ Starter'),
                                      ),
                                    _CompleteTaskButton(
                                      onPressed: onComplete,
                                      disableAnimations: disableAnimations,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskSurfaceTag extends StatelessWidget {
  const _TaskSurfaceTag({
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
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TaskInlineStatus extends StatelessWidget {
  const _TaskInlineStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CompleteTaskButton extends StatefulWidget {
  const _CompleteTaskButton({
    required this.onPressed,
    required this.disableAnimations,
  });

  final VoidCallback? onPressed;
  final bool disableAnimations;

  @override
  State<_CompleteTaskButton> createState() => _CompleteTaskButtonState();
}

class _CompleteTaskButtonState extends State<_CompleteTaskButton> {
  late final WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController()
      ..addListener(_handleStateChange);
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_handleStateChange)
      ..dispose();
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = _statesController.value;
    final isPressed = states.contains(WidgetState.pressed);
    final isHighlighted =
        isPressed ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    final successColor = const Color(0xFF3C9A5F);
    final duration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedScale(
      scale: isPressed ? 0.98 : 1,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: successColor.withValues(alpha: isPressed ? 0.16 : 0.20),
                blurRadius: isPressed ? 12 : 20,
                offset: Offset(0, isPressed ? 4 : 10),
              ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: widget.onPressed,
          statesController: _statesController,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Complete'),
          style: ButtonStyle(
            animationDuration: duration,
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            textStyle: WidgetStatePropertyAll(
              theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.surfaceContainerHighest;
              }
              if (states.contains(WidgetState.pressed)) {
                return successColor;
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return successColor.withValues(alpha: 0.92);
              }
              return theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.94,
              );
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                );
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return Colors.white;
              }
              return theme.colorScheme.onSurfaceVariant;
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return successColor.withValues(alpha: 0.08);
              }
              return null;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.10),
                );
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return BorderSide(color: successColor.withValues(alpha: 0.92));
              }
              return BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.68),
              );
            }),
            shape: const WidgetStatePropertyAll(StadiumBorder()),
          ),
        ),
      ),
    );
  }
}
