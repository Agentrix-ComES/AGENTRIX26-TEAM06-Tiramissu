import 'package:flutter/material.dart';
import '../theme/ayu_text_styles.dart';

/// Tappable stat card — value in coloured text, label in grey below.
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;
  final VoidCallback? onTap;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        lowerBound: 0.95,
        upperBound: 1.0,
        value: 1.0,
        duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.value,
                  style: AyuText.body(
                      size: 17.6,
                      weight: FontWeight.w800,
                      color: widget.valueColor)),
              const SizedBox(height: 2),
              Text(widget.label,
                  textAlign: TextAlign.center,
                  style: AyuText.label(
                      color: const Color(0xFF9FA49A),
                      size: 9.9,
                      weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
