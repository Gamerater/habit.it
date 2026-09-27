import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/habits_provider.dart';

/// Placeholder for the grid/list toggle view (screenshots 10-11 in the
/// research). Next step: build HabitGridTile + StreakRing widgets here.
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/habits/new'),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (habits) => ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, i) => ListTile(title: Text(habits[i].name)),
        ),
      ),
    );
  }
}
