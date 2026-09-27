import 'package:flutter/material.dart';

import '../domain/habit_icon.dart';

/// Pushed as a full route; pops with the selected icon id ("ic_xxx") or a
/// raw emoji string. Two tabs (Icon / Emoji) matching the reference app's
/// structure, but with a working search box up front instead of only
/// scrolling through categories.
class IconPickerScreen extends StatefulWidget {
  const IconPickerScreen({super.key});

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose an Icon'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Icon'), Tab(text: 'Emoji')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search icons',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IconGrid(query: _query),
                _EmojiGrid(query: _query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final String query;

  const _IconGrid({required this.query});

  @override
  Widget build(BuildContext context) {
    final categories = query.isEmpty
        ? HabitIconCatalog.categories
        : [
            HabitIconCategory(
              'Results',
              HabitIconCatalog.allIcons
                  .where((i) => i.label.toLowerCase().contains(query))
                  .toList(),
            ),
          ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final category in categories)
          if (category.icons.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: category.icons.length,
              itemBuilder: (context, i) {
                final option = category.icons[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(option.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(option.icon),
                  ),
                );
              },
            ),
          ],
      ],
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final String query;

  const _EmojiGrid({required this.query});

  @override
  Widget build(BuildContext context) {
    final categories = query.isEmpty
        ? HabitIconCatalog.emojiCategories
        : [
            HabitEmojiCategory(
              'Results',
              HabitIconCatalog.allEmojis
                  .where((e) => e.contains(query))
                  .toList(),
            ),
          ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final category in categories)
          if (category.emojis.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: category.emojis.length,
              itemBuilder: (context, i) {
                final emoji = category.emojis[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ],
      ],
    );
  }
}