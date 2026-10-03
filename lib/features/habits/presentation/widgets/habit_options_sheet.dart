import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/habit.dart';
import '../providers/habits_provider.dart';
import 'color_palette.dart';
import 'habit_avatar.dart';

/// Long-press on a habit card/row anywhere in the app opens this — Edit,
/// Archive/Unarchive, Delete (with confirmation).
Future<void> showHabitOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final accent = hexToColor(habit.color);

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(habit.name, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: accent),
              title: const Text('Edit habit'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/habits/edit', extra: habit);
              },
            ),
            ListTile(
              leading: Icon(
                habit.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: accent,
              ),
              title: Text(habit.isArchived ? 'Restore habit' : 'Archive habit'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref
                    .read(habitRepositoryProvider)
                    .archiveHabit(habit.id, archived: !habit.isArchived);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Delete habit', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete this habit?'),
                    content: Text(
                      '"${habit.name}" and all of its history will be permanently deleted. This can\'t be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(habitRepositoryProvider).deleteHabit(habit.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}