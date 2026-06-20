import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Editable form field used in ProfileScreen.
/// Shows a read-only display when [editing] is false, switches to a TextField when true.
class EditableField extends StatelessWidget {
  const EditableField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.editing,
    this.placeholder = '',
  });

  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool editing;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: editing ? AyuColors.white : AyuColors.sageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: editing ? AyuColors.lime : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AyuColors.sageLightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: AyuColors.sageDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AyuText.label(
                    color: AyuColors.textSubtle,
                    size: 10.9,
                    weight: FontWeight.w600,
                    letterSpacing: 0.04 * 11,
                  ),
                ),
                const SizedBox(height: 2),
                editing
                    ? TextField(
                        controller: TextEditingController(text: value)
                          ..selection = TextSelection.collapsed(
                              offset: value.length),
                        onChanged: onChanged,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: placeholder,
                          hintStyle: AyuText.body(
                              size: 14.4,
                              color: AyuColors.textLight,
                              weight: FontWeight.w600),
                        ),
                        style: AyuText.body(
                          size: 14.4,
                          weight: FontWeight.w600,
                          color: AyuColors.navy,
                        ),
                      )
                    : Text(
                        value.isNotEmpty ? value : (placeholder.isNotEmpty ? placeholder : 'Not set'),
                        style: AyuText.body(
                          size: 14.4,
                          weight: FontWeight.w600,
                          color: value.isNotEmpty
                              ? AyuColors.navy
                              : AyuColors.textLight,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
