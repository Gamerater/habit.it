import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../habits/presentation/providers/habits_provider.dart';

/// New relative to HabitKit's screenshots: a dedicated "today" checklist home
/// screen, rather than jumping straight into the multi-day grid.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final repo = ref.read(habitRepositoryProvider);
    final today = DateOnly.today();

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Something went wrong: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(int.parse(habit.color.replaceFirst('#', '0xFF'))),
                    child: Text(habit.icon),
                  ),
                  title: Text(habit.name),
                  subtitle: habit.description?.isNotEmpty == true
                      ? Text(habit.description!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => repo.setCompletion(
                      habitId: habit.id,
                      date: today,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No habits yet. Tap + to build or quit your first one.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
