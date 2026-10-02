/// A category/tag a habit can belong to (e.g. "Health", "Art") — shown as a
/// filter chip on the Habits screen and as a badge on the habit detail
/// screen. Icon uses the same "ic_xxx" / raw-emoji convention as habits.
class Category {
  final String id;
  final String name;
  final String icon;
  final String color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}