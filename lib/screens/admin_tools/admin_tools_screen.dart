import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/character_stats.dart';
import 'package:progress_potion/models/task.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  final _xpController = TextEditingController();
  final _strengthController = TextEditingController();
  final _vitalityController = TextEditingController();
  final _wisdomController = TextEditingController();
  final _mindfulnessController = TextEditingController();
  bool _isApplyingXp = false;
  bool _isApplyingStats = false;
  bool _isApplyingCharge = false;
  bool _isResetting = false;
  TaskCategory _selectedPotionCategory = TaskCategory.work;

  @override
  void dispose() {
    _xpController.dispose();
    _strengthController.dispose();
    _vitalityController.dispose();
    _wisdomController.dispose();
    _mindfulnessController.dispose();
    super.dispose();
  }

  Future<void> _grantXp() async {
    final xpDelta = _parsePositiveInt(_xpController.text);
    if (xpDelta == null) {
      _showMessage('Enter a positive whole number for XP.');
      return;
    }

    setState(() {
      _isApplyingXp = true;
    });

    final beforeXp = widget.taskController.totalXp;

    try {
      await widget.taskController.grantAdminProgress(
        xpDelta: xpDelta,
        statDelta: CharacterStats.zero,
      );
      _xpController.clear();
      _showMessage(
        'XP updated: $beforeXp -> ${widget.taskController.totalXp}.',
      );
    } on ArgumentError catch (error) {
      _showMessage(error.message?.toString() ?? 'Could not grant XP.');
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingXp = false;
        });
      }
    }
  }

  Future<void> _grantStats() async {
    final strength = _parseOptionalNonNegativeInt(_strengthController.text);
    final vitality = _parseOptionalNonNegativeInt(_vitalityController.text);
    final wisdom = _parseOptionalNonNegativeInt(_wisdomController.text);
    final mindfulness = _parseOptionalNonNegativeInt(
      _mindfulnessController.text,
    );

    if (strength == null ||
        vitality == null ||
        wisdom == null ||
        mindfulness == null) {
      _showMessage(
        'Use whole numbers for stats. Leave a field blank for zero.',
      );
      return;
    }

    final statDelta = CharacterStats(
      strength: strength,
      vitality: vitality,
      wisdom: wisdom,
      mindfulness: mindfulness,
    );

    if (statDelta.isZero) {
      _showMessage('Enter at least one positive stat gain.');
      return;
    }

    setState(() {
      _isApplyingStats = true;
    });

    final beforeStats = widget.taskController.stats;

    try {
      await widget.taskController.grantAdminProgress(
        xpDelta: 0,
        statDelta: statDelta,
      );
      _strengthController.clear();
      _vitalityController.clear();
      _wisdomController.clear();
      _mindfulnessController.clear();
      final afterStats = widget.taskController.stats;
      _showMessage(
        'Stats updated: '
        'STR ${beforeStats.strength} -> ${afterStats.strength}, '
        'VIT ${beforeStats.vitality} -> ${afterStats.vitality}, '
        'WIS ${beforeStats.wisdom} -> ${afterStats.wisdom}, '
        'MIN ${beforeStats.mindfulness} -> ${afterStats.mindfulness}.',
      );
    } on ArgumentError catch (error) {
      _showMessage(error.message?.toString() ?? 'Could not grant stats.');
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingStats = false;
        });
      }
    }
  }

  Future<void> _addPotionCharge() async {
    setState(() {
      _isApplyingCharge = true;
    });

    final beforeCount = widget.taskController.potionChargeCount;

    try {
      await widget.taskController.addAdminPotionCharge(_selectedPotionCategory);
      _showMessage(
        '${_selectedPotionCategory.displayName} charge added: '
        '$beforeCount -> ${widget.taskController.potionChargeCount}.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCharge = false;
        });
      }
    }
  }

  Future<void> _resetProgress() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset all saved progress?'),
          content: const Text(
            'This restores the seeded task list, potion queue, XP, and stats.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset progress'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      await widget.taskController.resetProgressToSeedState();
      _showMessage('Progress reset to the seeded baseline.');
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: AnimatedBuilder(
        animation: widget.taskController,
        builder: (context, _) {
          final stats = widget.taskController.stats;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug-only progression tools',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use these controls to test XP, stats, potion state, and reset behavior without going through the normal brew loop.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current session snapshot',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SnapshotChip(
                            label: 'XP',
                            value: '${widget.taskController.totalXp}',
                          ),
                          _SnapshotChip(
                            label: 'Potion charges',
                            value: '${widget.taskController.potionChargeCount}',
                          ),
                          _SnapshotChip(
                            label: 'Strength',
                            value: '${stats.strength}',
                          ),
                          _SnapshotChip(
                            label: 'Vitality',
                            value: '${stats.vitality}',
                          ),
                          _SnapshotChip(
                            label: 'Wisdom',
                            value: '${stats.wisdom}',
                          ),
                          _SnapshotChip(
                            label: 'Mindfulness',
                            value: '${stats.mindfulness}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AdminSectionCard(
                title: 'Grant XP',
                description:
                    'Add XP directly without changing tasks or potion progress.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('admin-xp-input'),
                      controller: _xpController,
                      enabled: !_isApplyingXp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP to add',
                        hintText: '25',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('admin-grant-xp-button'),
                      onPressed: _isApplyingXp ? null : _grantXp,
                      child: Text(_isApplyingXp ? 'Applying...' : 'Grant XP'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminSectionCard(
                title: 'Grant stats',
                description:
                    'Add gains to the existing four character stats in one action.',
                child: Column(
                  children: [
                    _StatField(
                      fieldKey: const ValueKey('admin-strength-input'),
                      controller: _strengthController,
                      label: 'Strength',
                      enabled: !_isApplyingStats,
                    ),
                    const SizedBox(height: 12),
                    _StatField(
                      fieldKey: const ValueKey('admin-vitality-input'),
                      controller: _vitalityController,
                      label: 'Vitality',
                      enabled: !_isApplyingStats,
                    ),
                    const SizedBox(height: 12),
                    _StatField(
                      fieldKey: const ValueKey('admin-wisdom-input'),
                      controller: _wisdomController,
                      label: 'Wisdom',
                      enabled: !_isApplyingStats,
                    ),
                    const SizedBox(height: 12),
                    _StatField(
                      fieldKey: const ValueKey('admin-mindfulness-input'),
                      controller: _mindfulnessController,
                      label: 'Mindfulness',
                      enabled: !_isApplyingStats,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        key: const ValueKey('admin-grant-stats-button'),
                        onPressed: _isApplyingStats ? null : _grantStats,
                        child: Text(
                          _isApplyingStats ? 'Applying...' : 'Grant stats',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminSectionCard(
                title: 'Add potion charge',
                description:
                    'Append one category charge at a time so you can test queue order and mixed brews.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<TaskCategory>(
                      key: const ValueKey('admin-potion-category-dropdown'),
                      initialValue: _selectedPotionCategory,
                      items: [
                        for (final category in TaskCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          ),
                      ],
                      onChanged: _isApplyingCharge
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedPotionCategory = value;
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Category charge',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('admin-add-charge-button'),
                      onPressed: _isApplyingCharge ? null : _addPotionCharge,
                      child: Text(
                        _isApplyingCharge ? 'Applying...' : 'Add potion charge',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminSectionCard(
                title: 'Reset progress',
                description:
                    'Restore the same seeded baseline used on first launch.',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    key: const ValueKey('admin-reset-button'),
                    onPressed: _isResetting ? null : _resetProgress,
                    style: FilledButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: Text(
                      _isResetting ? 'Resetting...' : 'Reset saved progress',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatField extends StatelessWidget {
  const _StatField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: '$label gain', hintText: '0'),
    );
  }
}

int? _parsePositiveInt(String rawValue) {
  final value = int.tryParse(rawValue.trim());
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

int? _parseOptionalNonNegativeInt(String rawValue) {
  final trimmedValue = rawValue.trim();
  if (trimmedValue.isEmpty) {
    return 0;
  }

  final value = int.tryParse(trimmedValue);
  if (value == null || value < 0) {
    return null;
  }
  return value;
}
