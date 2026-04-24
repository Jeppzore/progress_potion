import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.taskController,
    this.feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
  });

  final TaskController taskController;
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteSort _sort = FavoriteSort.mostUsed;

  bool _isCatalogItemActive(TaskCatalogItem item) {
    return widget.taskController.activeTasks.any(
      (task) =>
          task.title == item.title &&
          task.category == item.category &&
          task.description == item.description,
    );
  }

  Future<void> _activateFavorite(TaskCatalogItem item) async {
    final alreadyActive = _isCatalogItemActive(item);
    await widget.taskController.activateCatalogItem(item.id);
    if (!mounted) {
      return;
    }

    widget.feedbackSoundPlayer.play(
      alreadyActive ? FeedbackSound.buttonTap : FeedbackSound.taskCreate,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyActive ? 'Already in active.' : 'Added to active.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.taskController,
      builder: (context, _) {
        if (widget.taskController.error != null) {
          return const _AsyncStateMessage(
            icon: Icons.warning_amber_rounded,
            title: 'The cauldron needs a reset.',
            message: 'We could not load favorites for this session.',
          );
        }

        if (widget.taskController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = widget.taskController.favoriteCatalogItems(
          sort: _sort,
        );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F2E9), Color(0xFFF1E8DA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -40,
                child: _BackdropGlow(size: 280, color: const Color(0x334B8B70)),
              ),
              Positioned(
                top: 90,
                left: -60,
                child: _BackdropGlow(size: 220, color: const Color(0x22E06B4C)),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Favorites',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      SegmentedButton<FavoriteSort>(
                        segments: const [
                          ButtonSegment(
                            value: FavoriteSort.mostUsed,
                            icon: Icon(Icons.trending_up_rounded),
                            label: Text('Most used'),
                          ),
                          ButtonSegment(
                            value: FavoriteSort.libraryOrder,
                            icon: Icon(Icons.sort_rounded),
                            label: Text('Library'),
                          ),
                        ],
                        selected: {_sort},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          widget.feedbackSoundPlayer.play(
                            FeedbackSound.buttonTap,
                          );
                          setState(() {
                            _sort = selection.single;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (favorites.isEmpty)
                    const _EmptyStateCard(title: 'No favorites yet')
                  else
                    for (final item in favorites) ...[
                      _FavoriteTaskCard(
                        item: item,
                        isActive: _isCatalogItemActive(item),
                        onAdd: () => _activateFavorite(item),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteTaskCard extends StatelessWidget {
  const _FavoriteTaskCard({
    required this.item,
    required this.isActive,
    required this.onAdd,
  });

  final TaskCatalogItem item;
  final bool isActive;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedText = item.completedCount == 1
        ? 'Completed 1 time'
        : 'Completed ${item.completedCount} times';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _FavoriteTag(
                            label: item.category.displayName,
                            color: theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          _FavoriteTag(
                            label: completedText,
                            color: theme.colorScheme.primaryContainer,
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          if (item.isStarter)
                            _FavoriteTag(
                              label: 'Starter',
                              color: theme.colorScheme.secondaryContainer,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                          if (isActive)
                            _FavoriteTag(
                              label: 'Active',
                              color: theme.colorScheme.secondaryContainer,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: Icon(
                  isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_task_rounded,
                ),
                label: Text(isActive ? 'Already active' : 'Add to active'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTag extends StatelessWidget {
  const _FavoriteTag({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _AsyncStateMessage extends StatelessWidget {
  const _AsyncStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.color});

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
