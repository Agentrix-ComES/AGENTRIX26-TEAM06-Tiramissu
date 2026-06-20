import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Nearby-place list row with map-pin icon, name, distance, star rating, category tag.
class NearbyPlaceRow extends StatelessWidget {
  const NearbyPlaceRow({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.tag,
    this.onTap,
  });

  final String name;
  final String distance;
  final double rating;
  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AyuColors.sageLightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on,
                  size: 16, color: AyuColors.sageDeep),
            ),
            const SizedBox(width: 12),
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AyuText.body(
                          size: 14.4,
                          weight: FontWeight.w700,
                          color: AyuColors.navy)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(distance,
                          style: AyuText.label(
                              color: AyuColors.textSubtle, size: 12)),
                      const SizedBox(width: 6),
                      Text('•',
                          style: AyuText.label(
                              color: AyuColors.textLight, size: 11.2)),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded,
                          size: 12, color: AyuColors.star),
                      const SizedBox(width: 2),
                      Text(rating.toString(),
                          style: AyuText.label(
                              color: AyuColors.textSubtle, size: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AyuColors.sageLightBg,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(tag,
                            style: AyuText.label(
                                color: AyuColors.sageDeep,
                                size: 11.2,
                                weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 15, color: AyuColors.textLight),
          ],
        ),
      ),
    );
  }
}
