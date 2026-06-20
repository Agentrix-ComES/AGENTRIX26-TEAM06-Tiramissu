import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/feature_card.dart';
import '../widgets/nearby_place_row.dart';
import '../widgets/stat_card.dart';

const _chips = ['Smart Routes', 'Sight-Glass', 'Live Audio', 'Food', 'Culture'];

const _featureCards = [
  _FeatureData(
    id: 'routes',
    title: 'Smart Routes',
    subtitle: 'AI-powered itinerary planner for your journey',
    imageUrl:
        'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    tag: 'AI Planner',
    icon: Icons.navigation_rounded,
    color: AyuColors.lime,
    target: 'routes',
  ),
  _FeatureData(
    id: 'sightglass',
    title: 'Sight-Glass',
    subtitle: 'Point your camera at menus or signs to translate instantly',
    imageUrl:
        'https://images.unsplash.com/photo-1698063261670-72d63ee5c1a3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    tag: 'AR Camera',
    icon: Icons.camera_alt_rounded,
    color: AyuColors.sageAccent,
    target: 'guardian',
  ),
  _FeatureData(
    id: 'guardian',
    title: 'The Guardian',
    subtitle: 'Live audio scam detection — always protecting you',
    imageUrl:
        'https://images.unsplash.com/photo-1776331483698-f7e8499bbe74?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    tag: 'Live Shield',
    icon: Icons.shield_rounded,
    color: Color(0xFFFFB3B3),
    target: 'guardian',
  ),
];

class _FeatureData {
  final String id, title, subtitle, imageUrl, tag, target;
  final IconData icon;
  final Color color;
  const _FeatureData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tag,
    required this.icon,
    required this.color,
    required this.target,
  });
}

const _nearbyPlaces = [
  _PlaceData(name: 'Gangarama Temple', dist: '0.8 km', rating: 4.8, tag: 'Temple'),
  _PlaceData(name: 'Galle Face Green', dist: '1.2 km', rating: 4.6, tag: 'Park'),
  _PlaceData(name: 'Barefoot Gallery', dist: '2.1 km', rating: 4.5, tag: 'Culture'),
];

class _PlaceData {
  final String name, dist, tag;
  final double rating;
  const _PlaceData({required this.name, required this.dist, required this.rating, required this.tag});
}

/// Main dashboard screen with filter chips, feature cards, nearby places, stats, and nav bar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.activeNav = 'explore',
  });

  final ValueChanged<String> onNavigate;
  final String activeNav;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeChip = 0;

  static final _navItems = [
    const AyuNavItem(icon: Icons.explore_rounded, label: 'Explore', target: 'explore'),
    const AyuNavItem(icon: Icons.map_rounded, label: 'Routes', target: 'routes'),
    const AyuNavItem(icon: Icons.mic_rounded, label: 'Guardian', target: 'guardian'),
    const AyuNavItem(icon: Icons.notifications_rounded, label: 'Alerts', target: 'alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AyuColors.sageBg,
      child: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterChips(),
                _buildSectionHeader('Core Features', 'See all'),
                _buildFeatureCards(),
                _buildSectionHeader('Nearby Highlights', 'Map view',
                    onRight: () => widget.onNavigate('routes')),
                _buildNearbyPlaces(),
                _buildProtectionSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Floating nav bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FloatingNavBar(
              items: _navItems,
              active: widget.activeNav,
              onTap: widget.onNavigate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 13, color: AyuColors.sage),
                  const SizedBox(width: 4),
                  Text('Colombo, Sri Lanka',
                      style: AyuText.label(
                          color: AyuColors.sage,
                          size: 12,
                          weight: FontWeight.w600,
                          letterSpacing: 0.02 * 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Hello, Traveler! 👋', style: AyuText.h1()),
            ],
          ),
          // Avatar → profile
          GestureDetector(
            onTap: () => widget.onNavigate('profile'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AyuColors.lime, width: 2.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1520466809213-7b9a56adcd45?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AyuColors.sageLightBg),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AyuColors.lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: AyuColors.white, width: 2),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 2,
                        backgroundColor: AyuColors.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                size: 16, color: AyuColors.textSubtle),
            const SizedBox(width: 12),
            Text('Search destinations, foods, sights…',
                style: AyuText.body(
                    color: AyuColors.textPlaceholder, size: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _activeChip == i;
          return GestureDetector(
            onTap: () => setState(() => _activeChip = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AyuColors.lime : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
                border: active
                    ? null
                    : Border.all(color: AyuColors.borderLight, width: 1.5),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF96C828).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _chips[i],
                style: AyuText.chip(
                    color: active ? AyuColors.navy : AyuColors.textMuted,
                    active: active),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action,
      {VoidCallback? onRight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(
        top: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AyuText.body(size: 16.8, weight: FontWeight.w700)),
          GestureDetector(
            onTap: onRight,
            child: Text(action,
                style: AyuText.label(
                    color: AyuColors.sage,
                    size: 12.8,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return SizedBox(
      height: 304,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _featureCards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = _featureCards[i];
          return FeatureCard(
            title: c.title,
            subtitle: c.subtitle,
            imageUrl: c.imageUrl,
            tag: c.tag,
            accentColor: c.color,
            icon: c.icon,
            onTap: () => widget.onNavigate(c.target),
          );
        },
      ),
    );
  }

  Widget _buildNearbyPlaces() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _nearbyPlaces
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NearbyPlaceRow(
                    name: p.name,
                    distance: p.dist,
                    rating: p.rating,
                    tag: p.tag,
                    onTap: () => widget.onNavigate('smartRoutes'),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProtectionSection() {
    final stats = [
      _StatData(label: 'Scams blocked', value: '3', color: AyuColors.danger, bg: AyuColors.dangerBg, action: 'alerts'),
      _StatData(label: 'Money saved', value: '₨11.8K', color: AyuColors.success, bg: AyuColors.successBg, action: 'alerts'),
      _StatData(label: 'Smart routes', value: '7', color: AyuColors.info, bg: AyuColors.infoBg, action: 'smartRoutes'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
          child: Text('Your Protection',
              style: AyuText.body(size: 16.8, weight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: stats
                .map((s) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: s == stats.last ? 0 : 12),
                        child: StatCard(
                          label: s.label,
                          value: s.value,
                          valueColor: s.color,
                          bgColor: s.bg,
                          onTap: () => widget.onNavigate(s.action),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatData {
  final String label, value, action;
  final Color color, bg;
  const _StatData({required this.label, required this.value, required this.color, required this.bg, required this.action});
}
