import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Uppercase green section label with icon — used in ProfileScreen.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AyuColors.sage),
          const SizedBox(width: 8),
          Text(label.toUpperCase(), style: AyuText.sectionLabel()),
        ],
      ),
    );
  }
}
