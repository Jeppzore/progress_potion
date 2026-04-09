import 'package:flutter/material.dart';
import 'package:progress_potion/models/habit.dart';
import 'package:progress_potion/services/habit_service.dart';
import 'package:progress_potion/widgets/habit_preview_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.habitService});

  final HabitService habitService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Habit>> _habitsFuture;

  @override
  void initState() {
    super.initState();
    _habitsFuture = widget.habitService.listHabits();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Habit>>(
      future: _habitsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AsyncStateMessage(
            icon: Icons.warning_amber_rounded,
            title: 'We could not brew your habits.',
            message: 'Check the service layer before wiring in real data.',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = snapshot.data!;
        final completedToday = habits
            .where((habit) => habit.isCompletedToday)
            .length;
        final strongestStreak = habits
            .map((habit) => habit.currentStreak)
            .fold<int>(0, (best, streak) => streak > best ? streak : best);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _HeroBanner(
              title: "Today's momentum",
              message:
                  'Build momentum one repeat at a time. Phase 1 gives us the shell, seeded habits, and room to grow into full tracking.',
              trailing: Text(
                '$completedToday/${habits.length} brewed',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HomeStatCard(
                  label: 'Active rituals',
                  value: '${habits.length}',
                  helper: 'Seeded habits ready for Phase 2',
                ),
                _HomeStatCard(
                  label: 'Completed today',
                  value: '$completedToday',
                  helper: 'Read-only progress for the shell',
                ),
                _HomeStatCard(
                  label: 'Best streak',
                  value: '$strongestStreak days',
                  helper: 'Longest streak in the demo set',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Active Habits',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'These cards prove the Phase 1 data flow from service to UI.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final habit in habits) ...[
              HabitPreviewCard(habit: habit),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.message,
    required this.trailing,
  });

  final String title;
  final String message;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF24584A), Color(0xFFDB9C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          trailing,
        ],
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(helper, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
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
