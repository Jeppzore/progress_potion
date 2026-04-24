import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/task.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.taskController,
    this.feedbackSoundPlayer = const NoOpFeedbackSoundPlayer(),
  });

  final TaskController taskController;
  final FeedbackSoundPlayer feedbackSoundPlayer;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.values.first;
  bool _isCreatingTask = false;
  bool _isSavingNewTask = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<TaskCatalogItem> _catalogItemsFor(TaskCategory category) {
    final items = widget.taskController.getCatalogByCategory(category).toList();
    items.sort(_compareCatalogItems);
    return items;
  }

  int _compareCatalogItems(TaskCatalogItem left, TaskCatalogItem right) {
    if (left.isFavorite != right.isFavorite) {
      return left.isFavorite ? -1 : 1;
    }

    if (left.isDefault != right.isDefault) {
      return left.isDefault ? 1 : -1;
    }

    final titleComparison = left.title.compareTo(right.title);
    if (titleComparison != 0) {
      return titleComparison;
    }

    return left.id.compareTo(right.id);
  }

  bool _isCatalogItemActive(TaskCatalogItem item) {
    return widget.taskController.activeTasks.any(
      (task) =>
          task.title == item.title &&
          task.category == item.category &&
          task.description == item.description,
    );
  }

  void _playButtonTap() {
    widget.feedbackSoundPlayer.play(FeedbackSound.buttonTap);
  }

  Future<void> _activateCatalogItem(TaskCatalogItem item) async {
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
        content: Text(alreadyActive ? 'Already in active.' : 'Added to active.'),
      ),
    );
  }

  Future<void> _toggleFavorite(TaskCatalogItem item) async {
    _playButtonTap();
    await widget.taskController.toggleFavorite(item.id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleStarter(TaskCatalogItem item) async {
    _playButtonTap();
    await widget.taskController.toggleStarter(item.id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteCatalogItem(TaskCatalogItem item) async {
    _playButtonTap();
    await widget.taskController.deleteUserCatalogItem(item.id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createCatalogItem() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSavingNewTask = true;
    });

    try {
      await widget.taskController.createCatalogItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      if (!mounted) {
        return;
      }

      widget.feedbackSoundPlayer.play(FeedbackSound.taskCreate);
      setState(() {
        _isCreatingTask = false;
        _titleController.clear();
        _descriptionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${_selectedCategory.displayName}.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this task. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNewTask = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.taskController,
      builder: (context, _) {
        final categoryItems = _catalogItemsFor(_selectedCategory);

        return Scaffold(
          appBar: AppBar(title: const Text('Task library')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in TaskCategory.values)
                    ChoiceChip(
                      key: ValueKey('task-library-category-${category.name}'),
                      label: Text(category.displayName),
                      showCheckmark: false,
                      selected: _selectedCategory == category,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _selectedCategory == category
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      selectedColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: _selectedCategory == category
                            ? Colors.transparent
                            : theme.colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      onSelected: _isSavingNewTask
                          ? null
                          : (isSelected) {
                              if (!isSelected) {
                                return;
                              }

                              _playButtonTap();
                              setState(() {
                                _selectedCategory = category;
                                _isCreatingTask = false;
                              });
                            },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _LibrarySectionHeader(title: _selectedCategory.displayName),
              const SizedBox(height: 10),
              if (categoryItems.isEmpty)
                _EmptyLibraryCard(
                  onCreatePressed: () {
                    _playButtonTap();
                    setState(() {
                      _isCreatingTask = true;
                    });
                  },
                )
              else
                for (final item in categoryItems) ...[
                  _LibraryTaskCard(
                    title: item.title,
                    description: item.description,
                    category: item.category,
                    isFavorite: item.isFavorite,
                    isStarter: item.isStarter,
                    onAdd: _isSavingNewTask
                        ? null
                        : () => _activateCatalogItem(item),
                    onFavoriteToggle: _isSavingNewTask
                        ? null
                        : () => _toggleFavorite(item),
                    onStarterToggle: _isSavingNewTask
                        ? null
                        : () => _toggleStarter(item),
                    onDelete: item.isDefault || _isSavingNewTask
                        ? null
                        : () => _deleteCatalogItem(item),
                  ),
                  const SizedBox(height: 10),
                ],
              if (_isCreatingTask) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New task',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _titleController,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Task title',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Task title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _isSavingNewTask
                                    ? null
                                    : () {
                                        _playButtonTap();
                                        setState(() {
                                          _isCreatingTask = false;
                                        });
                                      },
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: _isSavingNewTask
                                    ? null
                                    : _createCatalogItem,
                                icon: _isSavingNewTask
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(
                                  _isSavingNewTask
                                      ? 'Saving...'
                                      : 'Save to library',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isSavingNewTask
                        ? null
                        : () {
                            _playButtonTap();
                            setState(() {
                              _isCreatingTask = true;
                            });
                          },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create new task'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LibrarySectionHeader extends StatelessWidget {
  const _LibrarySectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyLibraryCard extends StatelessWidget {
  const _EmptyLibraryCard({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No tasks here yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Create new task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTaskCard extends StatelessWidget {
  const _LibraryTaskCard({
    required this.title,
    required this.description,
    required this.category,
    required this.isFavorite,
    required this.isStarter,
    required this.onAdd,
    required this.onFavoriteToggle,
    required this.onStarterToggle,
    required this.onDelete,
  });

  final String title;
  final String description;
  final TaskCategory category;
  final bool isFavorite;
  final bool isStarter;
  final VoidCallback? onAdd;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onStarterToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _LibraryTag(
                            label: category.displayName,
                            color: theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          if (isStarter)
                            _LibraryTag(
                              label: 'Starter',
                              color: theme.colorScheme.primaryContainer,
                              textColor: theme.colorScheme.onPrimaryContainer,
                            ),
                          if (isFavorite)
                            _LibraryTag(
                              label: 'Favorite',
                              color: theme.colorScheme.primaryContainer,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    Semantics(
                      button: true,
                      label: isFavorite
                          ? 'Remove from favorites'
                          : 'Mark as favorite',
                      child: IconButton.filledTonal(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: isStarter
                          ? 'Remove starter task'
                          : 'Mark as starter task',
                      child: IconButton.filledTonal(
                        onPressed: onStarterToggle,
                        icon: Icon(
                          isStarter
                              ? Icons.play_circle_rounded
                              : Icons.play_circle_outline_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: onAdd,
                  child: const Text('Add to active'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTag extends StatelessWidget {
  const _LibraryTag({
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
