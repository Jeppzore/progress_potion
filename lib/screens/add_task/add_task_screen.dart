import 'package:flutter/material.dart';
import 'package:progress_potion/controllers/task_controller.dart';
import 'package:progress_potion/models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskCategory? _selectedCategory;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.taskController.addTask(
      title: _titleController.text,
      category: _selectedCategory!,
      description: _descriptionController.text,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add task')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brew a task',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What do you want to brew next?',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        hintText: 'Ship the onboarding copy',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Task title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Add a little context so the next action feels obvious.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Variety helps your potion earn bonus XP.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    FormField<TaskCategory>(
                      initialValue: _selectedCategory,
                      validator: (value) {
                        if (value == null) {
                          return 'Choose a category';
                        }
                        return null;
                      },
                      builder: (field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final category in TaskCategory.values)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: Semantics(
                                      selected: field.value == category,
                                      child: ChoiceChip(
                                        label: Text(category.displayName),
                                        selected: field.value == category,
                                        onSelected: _isSaving
                                            ? null
                                            : (isSelected) {
                                                final selectedCategory =
                                                    isSelected
                                                    ? category
                                                    : null;
                                                field.didChange(
                                                  selectedCategory,
                                                );
                                                setState(() {
                                                  _selectedCategory =
                                                      selectedCategory;
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (field.hasError) ...[
                              const SizedBox(height: 8),
                              Text(
                                field.errorText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveTask,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isSaving ? 'Saving...' : 'Add task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
