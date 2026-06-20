import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Feature card for the Dashboard horizontal scroll — 215×290 with image background.
class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tag,
    required this.accentColor,
    required this.icon,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onTap;
  final Duration animationDelay;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
      duration: const Duration(milliseconds: 120),
    );
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
        builder: (ctx, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          width: 215,
          height: 290,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AyuColors.sageBg,
                ),
              ),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              // Top-left tag pill
              Positioned(
                top: 12,
                left: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    color: Colors.white.withOpacity(0.22),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    child: Text(
                      widget.tag,
                      style: AyuText.label(
                        color: AyuColors.white,
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              // Top-right icon circle
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 15, color: AyuColors.navy),
                ),
              ),
              // Bottom text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title,
                          style: AyuText.h3(color: AyuColors.white)),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: AyuText.label(
                          color: Colors.white.withOpacity(0.75),
                          size: 12,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
