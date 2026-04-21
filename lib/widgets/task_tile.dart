import 'package:flutter/material.dart';
import 'package:progress_potion/models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onComplete,
    this.onRemove,
  });

  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final badgeColor = task.isCompleted
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final cardColor = task.isCompleted
        ? theme.colorScheme.surface
        : Colors.white.withValues(alpha: 0.92);
    final sideAccent = task.isCompleted
        ? theme.colorScheme.tertiary
        : theme.colorScheme.secondary;

    return Card(
      color: cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.74,
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
                            task.isCompleted ? 'Completed' : 'Active',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: 'Category ${task.category.displayName}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          task.category.displayName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: task.isCompleted
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
                      child: task.isCompleted
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Done',
                                  style: theme.textTheme.labelLarge?.copyWith(
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
