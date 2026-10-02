import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';
import '../../../icon_picker/presentation/icon_picker_screen.dart';
import '../providers/categories_provider.dart';

/// Pushed as a full route; pops with the final selected List<String> of
/// category ids. Supports creating a brand new category inline so the user
/// never has to leave the flow to set one up.
class CategoryPickerScreen extends ConsumerStatefulWidget {
  final List<String> initiallySelected;

  const CategoryPickerScreen({super.key, required this.initiallySelected});

  @override
  ConsumerState<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends ConsumerState<CategoryPickerScreen> {
  late final Set<String> _selected = {...widget.initiallySelected};

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    String icon = 'ic_favorite';
    String color = habitColorPalette.first;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Category', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(sheetContext).push<String>(
                        MaterialPageRoute(builder: (_) => const IconPickerScreen()),
                      );
                      if (result != null) setSheetState(() => icon = result);
                    },
                    child: HabitAvatar(icon: icon, colorHex: color, size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Category name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ColorPaletteGrid(
                selectedHex: color,
                onSelected: (hex) => setSheetState(() => color = hex),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      final id = await ref.read(habitRepositoryProvider).createCategory(
            name: nameController.text.trim(),
            icon: icon,
            color: color,
          );
      setState(() => _selected.add(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected.toList()),
            child: const Text('Done'),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final category in categories)
                CheckboxListTile(
                  value: _selected.contains(category.id),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(category.id);
                    } else {
                      _selected.remove(category.id);
                    }
                  }),
                  secondary: HabitAvatar(icon: category.icon, colorHex: category.color, size: 36),
                  title: Text(category.name),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _createCategory,
                icon: const Icon(Icons.add),
                label: const Text('New Category'),
              ),
            ],
          );
        },
      ),
    );
  }
}