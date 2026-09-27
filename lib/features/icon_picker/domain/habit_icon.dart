import 'package:flutter/material.dart';

/// A single selectable icon in the picker. Persisted to the DB as [id]
/// prefixed with "ic_" (see HabitAvatar for the decode side).
class HabitIconOption {
  final String id;
  final String label;
  final IconData icon;

  const HabitIconOption(this.id, this.label, this.icon);
}

class HabitIconCategory {
  final String name;
  final List<HabitIconOption> icons;

  const HabitIconCategory(this.name, this.icons);
}

class HabitEmojiCategory {
  final String name;
  final List<String> emojis;

  const HabitEmojiCategory(this.name, this.emojis);
}

/// The full icon catalog, grouped by category for browsing and flattened
/// for search. Deliberately curated around actual habit use cases (fitness,
/// focus, quitting things) rather than a generic "every Material icon" dump.
class HabitIconCatalog {
  static const List<HabitIconCategory> categories = [
    HabitIconCategory('Health & Fitness', [
      HabitIconOption('ic_fitness_center', 'Workout', Icons.fitness_center),
      HabitIconOption('ic_directions_run', 'Running', Icons.directions_run),
      HabitIconOption('ic_directions_bike', 'Cycling', Icons.directions_bike),
      HabitIconOption('ic_pool', 'Swimming', Icons.pool),
      HabitIconOption('ic_self_improvement', 'Yoga', Icons.self_improvement),
      HabitIconOption('ic_sports_basketball', 'Basketball', Icons.sports_basketball),
      HabitIconOption('ic_monitor_heart', 'Heart rate', Icons.monitor_heart),
      HabitIconOption('ic_bedtime', 'Sleep', Icons.bedtime),
      HabitIconOption('ic_wb_sunny', 'Morning', Icons.wb_sunny),
      HabitIconOption('ic_local_drink', 'Water', Icons.local_drink),
    ]),
    HabitIconCategory('Mind & Focus', [
      HabitIconOption('ic_self_improvement_2', 'Meditate', Icons.spa),
      HabitIconOption('ic_menu_book', 'Reading', Icons.menu_book),
      HabitIconOption('ic_edit_note', 'Journaling', Icons.edit_note),
      HabitIconOption('ic_school', 'Study', Icons.school),
      HabitIconOption('ic_translate', 'Language', Icons.translate),
      HabitIconOption('ic_psychology', 'Mindset', Icons.psychology),
      HabitIconOption('ic_headphones', 'Podcast', Icons.headphones),
    ]),
    HabitIconCategory('Creativity', [
      HabitIconOption('ic_brush', 'Painting', Icons.brush),
      HabitIconOption('ic_music_note', 'Music', Icons.music_note),
      HabitIconOption('ic_piano', 'Piano', Icons.piano),
      HabitIconOption('ic_camera_alt', 'Photography', Icons.camera_alt),
      HabitIconOption('ic_create', 'Writing', Icons.create),
      HabitIconOption('ic_theater_comedy', 'Practice', Icons.theater_comedy),
    ]),
    HabitIconCategory('Productivity', [
      HabitIconOption('ic_work', 'Work', Icons.work_outline),
      HabitIconOption('ic_checklist', 'Tasks', Icons.checklist),
      HabitIconOption('ic_alarm', 'Wake up', Icons.alarm),
      HabitIconOption('ic_savings', 'Save money', Icons.savings),
      HabitIconOption('ic_attach_money', 'Budget', Icons.attach_money),
      HabitIconOption('ic_home_repair_service', 'Chores', Icons.home_repair_service),
      HabitIconOption('ic_eco', 'Sustainability', Icons.eco),
    ]),
    HabitIconCategory('Food & Drink', [
      HabitIconOption('ic_restaurant', 'Meal', Icons.restaurant),
      HabitIconOption('ic_local_cafe', 'Coffee', Icons.local_cafe),
      HabitIconOption('ic_set_meal', 'Healthy eating', Icons.set_meal),
      HabitIconOption('ic_no_food', 'Fasting', Icons.no_food),
    ]),
    HabitIconCategory('Quitting', [
      HabitIconOption('ic_smoke_free', 'No smoking', Icons.smoke_free),
      HabitIconOption('ic_no_drinks', 'No alcohol', Icons.no_drinks),
      HabitIconOption('ic_block', 'No sugar', Icons.block),
      HabitIconOption('ic_phonelink_off', 'Less screen time', Icons.phonelink_off),
      HabitIconOption('ic_money_off', 'No spending', Icons.money_off),
      HabitIconOption('ic_do_not_disturb', 'Stop a habit', Icons.do_not_disturb_on),
    ]),
    HabitIconCategory('People & Places', [
      HabitIconOption('ic_favorite', 'Relationships', Icons.favorite_border),
      HabitIconOption('ic_pets', 'Pet care', Icons.pets),
      HabitIconOption('ic_park', 'Outdoors', Icons.park),
      HabitIconOption('ic_home', 'Home', Icons.home_outlined),
      HabitIconOption('ic_flight', 'Travel', Icons.flight_outlined),
    ]),
  ];

  static List<HabitIconOption> get allIcons =>
      categories.expand((c) => c.icons).toList();

  static IconData? iconFor(String id) {
    for (final option in allIcons) {
      if (option.id == id) return option.icon;
    }
    return null;
  }

  static const List<HabitEmojiCategory> emojiCategories = [
    HabitEmojiCategory('Health & Fitness', [
      '💪', '🏃', '🚴', '🏊', '🧘', '🏀', '⚽', '🥗', '💧', '😴',
    ]),
    HabitEmojiCategory('Mind & Focus', [
      '🧠', '📖', '📝', '🎓', '🗣️', '🎧', '☕',
    ]),
    HabitEmojiCategory('Creativity', [
      '🎨', '🎵', '🎹', '📷', '✍️', '🎭',
    ]),
    HabitEmojiCategory('Productivity', [
      '💼', '✅', '⏰', '💰', '🧹', '🌱',
    ]),
    HabitEmojiCategory('Food & Drink', [
      '🍽️', '🍵', '🥦', '🚫🍔',
    ]),
    HabitEmojiCategory('Quitting', [
      '🚭', '🍷', '🍬', '📵', '🛑',
    ]),
    HabitEmojiCategory('People & Places', [
      '❤️', '🐾', '🌳', '🏠', '✈️',
    ]),
  ];

  static List<String> get allEmojis =>
      emojiCategories.expand((c) => c.emojis).toList();
}