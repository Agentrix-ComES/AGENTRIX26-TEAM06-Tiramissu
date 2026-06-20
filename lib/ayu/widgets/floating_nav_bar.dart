import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

typedef NavTarget = String;

class AyuNavItem {
  final IconData icon;
  final String label;
  final String target;
  const AyuNavItem({required this.icon, required this.label, required this.target});
}

/// Glassmorphic floating bottom navigation bar — mirrors the React Dashboard nav pill.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.active,
    required this.onTap,
  });

  final List<AyuNavItem> items;
  final String active;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                final isActive = active == item.target;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(item.target),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AyuNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.reverse(),
      onTapUp: (_) {
        _scale.forward();
        widget.onTap();
      },
      onTapCancel: () => _scale.forward(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AyuColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alerts badge
              widget.item.label == 'Alerts'
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          widget.item.icon,
                          size: 18,
                          color: widget.isActive
                              ? AyuColors.navy
                              : AyuColors.textSubtle,
                        ),
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AyuColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      widget.item.icon,
                      size: 18,
                      color: widget.isActive
                          ? AyuColors.navy
                          : AyuColors.textSubtle,
                    ),
              if (widget.isActive) ...[
                const SizedBox(height: 2),
                Text(
                  widget.item.label,
                  style: AyuText.label(
                    color: AyuColors.navy,
                    size: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
