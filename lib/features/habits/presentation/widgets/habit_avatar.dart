import 'package:flutter/material.dart';

import '../../../icon_picker/domain/habit_icon.dart';
import 'color_palette.dart';

/// Renders a habit's icon/emoji as a soft, tinted rounded-square "app icon"
/// style avatar — one consistent visual language used on Today, Habits, and
/// the Add/Edit screen. Deliberately not a fully-saturated filled circle
/// (the generic default); the tint keeps it calm and premium-feeling even
/// when many habits are listed together.
class HabitAvatar extends StatelessWidget {
  final String icon;
  final String colorHex;
  final double size;

  const HabitAvatar({
    super.key,
    required this.icon,
    required this.colorHex,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(colorHex);
    final isIcon = icon.startsWith('ic_');
    final iconData = isIcon ? HabitIconCatalog.iconFor(icon) : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: isIcon && iconData != null
          ? Icon(iconData, color: color, size: size * 0.52)
          : Text(icon, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}