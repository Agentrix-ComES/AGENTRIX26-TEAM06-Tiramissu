import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import 'offline_pack_card.dart';
import '../data/offline_cache_manager.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;

  const PlaceDetailsSheet({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it was auto-synced
    bool isReadyOffline = OfflineCacheManager().isPlaceCached(title);

    return Container(
      decoration: const BoxDecoration(
        color: AyuColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AyuColors.borderLight,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AyuColors.sageBg,
                  child: const Center(child: Icon(Icons.image, color: AyuColors.sage)),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AyuText.h2(),
                      ),
                    ),
                    if (isReadyOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC6F621).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC6F621)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.offline_bolt, size: 14, color: Color(0xFF1E293B)),
                            SizedBox(width: 4),
                            Text("Available Offline", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AyuText.body(
                    color: AyuColors.textMuted,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Offline Pack Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OfflinePackCard(
              title: '$title Offline Pack',
              subtitle: 'Save route data for dead zones.',
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
