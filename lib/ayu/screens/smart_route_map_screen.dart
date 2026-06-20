import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import 'dart:math';

// ── Data Model ──────────────────────────────────────────────────────────────
class KandyAttraction {
  final String name;
  final String emoji;
  final LatLng position;
  final String transport;
  final String transportIcon;
  final int costLkr;
  final int durationMins;
  final String description;
  final Color markerColor;

  const KandyAttraction({
    required this.name,
    required this.emoji,
    required this.position,
    required this.transport,
    required this.transportIcon,
    required this.costLkr,
    required this.durationMins,
    required this.description,
    required this.markerColor,
  });
}

const _userLocation = LatLng(7.2906, 80.6337); // Kandy city center

final _kandyAttractions = [
  KandyAttraction(
    name: 'Dalada Maligawa',
    emoji: '🏛️',
    position: LatLng(7.2936, 80.6413),
    transport: 'Walk',
    transportIcon: '🚶',
    costLkr: 0,
    durationMins: 8,
    description: 'Sacred Temple of the Tooth Relic. UNESCO World Heritage Site. Entry LKR 1500 for foreigners.',
    markerColor: Color(0xFF7C3AED),
  ),
  KandyAttraction(
    name: 'Kandy Lake',
    emoji: '🏞️',
    position: LatLng(7.2910, 80.6417),
    transport: 'Walk',
    transportIcon: '🚶',
    costLkr: 0,
    durationMins: 5,
    description: 'Scenic artificial lake built by the last Kandyan king. A serene walk along the promenade.',
    markerColor: Color(0xFF0891B2),
  ),
  KandyAttraction(
    name: 'Peradeniya Botanical Gardens',
    emoji: '🌿',
    position: LatLng(7.2680, 80.5960),
    transport: 'Tuk-Tuk',
    transportIcon: '🛺',
    costLkr: 400,
    durationMins: 22,
    description: 'Royal Botanical Gardens spanning 147 acres. Home to over 4,000 species of plants.',
    markerColor: Color(0xFF059669),
  ),
  KandyAttraction(
    name: 'Udawatta Kele Sanctuary',
    emoji: '🌳',
    position: LatLng(7.2980, 80.6400),
    transport: 'Walk',
    transportIcon: '🚶',
    costLkr: 0,
    durationMins: 12,
    description: 'Ancient royal forest reserve with rich biodiversity. Perfect for birdwatching.',
    markerColor: Color(0xFF16A34A),
  ),
  KandyAttraction(
    name: 'Bahiravokanda Buddha',
    emoji: '🙏',
    position: LatLng(7.2945, 80.6330),
    transport: 'Tuk-Tuk',
    transportIcon: '🛺',
    costLkr: 250,
    durationMins: 10,
    description: 'Giant white Buddha statue overlooking the city. Panoramic views of Kandy valley.',
    markerColor: Color(0xFFF59E0B),
  ),
  KandyAttraction(
    name: 'Kandy Market',
    emoji: '🛒',
    position: LatLng(7.2956, 80.6360),
    transport: 'Walk',
    transportIcon: '🚶',
    costLkr: 0,
    durationMins: 6,
    description: 'Vibrant local market. Best place for spices, batik, and authentic Sri Lankan street food.',
    markerColor: Color(0xFFDC2626),
  ),
  KandyAttraction(
    name: 'Lankatilaka Temple',
    emoji: '⛩️',
    position: LatLng(7.2750, 80.5820),
    transport: 'Bus',
    transportIcon: '🚌',
    costLkr: 120,
    durationMins: 35,
    description: '14th century rock temple with stunning architecture and ancient murals.',
    markerColor: Color(0xFFEA580C),
  ),
  KandyAttraction(
    name: 'Ambuluwawa Tower',
    emoji: '🗼',
    position: LatLng(7.2520, 80.6100),
    transport: 'Tuk-Tuk',
    transportIcon: '🛺',
    costLkr: 600,
    durationMins: 40,
    description: 'Unique spiral tower offering 360° views of four provinces. A must-visit adventure spot.',
    markerColor: Color(0xFFDB2777),
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────
class SmartRouteMapScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SmartRouteMapScreen({super.key, this.onBack});

  @override
  State<SmartRouteMapScreen> createState() => _SmartRouteMapScreenState();
}

class _SmartRouteMapScreenState extends State<SmartRouteMapScreen>
    with SingleTickerProviderStateMixin {
  KandyAttraction? _selected;
  bool _isFindingRoute = false;
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectAttraction(KandyAttraction a) {
    setState(() => _selected = a);
    _mapController.move(
      LatLng(a.position.latitude - 0.005, a.position.longitude),
      14.5,
    );
  }

  void _surpriseMe() async {
    setState(() {
      _selected = null;
      _isFindingRoute = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    final random = Random();
    final pick = _kandyAttractions[random.nextInt(_kandyAttractions.length)];
    if (mounted) {
      setState(() => _isFindingRoute = false);
      _selectAttraction(pick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(7.2906, 80.6337),
              initialZoom: 14.0,
              minZoom: 12.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.comes.travelbokka',
              ),

              // Route line to selected place
              if (_selected != null)
                PolylineLayer(
                  polylines: [
                    Polyline<Object>(
                      points: [_userLocation, _selected!.position],
                      color: _selected!.markerColor,
                      strokeWidth: 4.0,
                      pattern: StrokePattern.dashed(segments: [12.0, 8.0]),
                    ),
                  ],
                ),

              // Attraction markers
              MarkerLayer(
                markers: [
                  // User location pulse marker
                  Marker(
                    point: _userLocation,
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44 * _pulseAnim.value,
                            height: 44 * _pulseAnim.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC6F621).withOpacity(0.25 * _pulseAnim.value),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC6F621),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC6F621).withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Attraction markers
                  ..._kandyAttractions.map((a) {
                    final isSelected = _selected?.name == a.name;
                    return Marker(
                      point: a.position,
                      width: isSelected ? 64 : 48,
                      height: isSelected ? 64 : 48,
                      child: GestureDetector(
                        onTap: () => _selectAttraction(a),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.elasticOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSelected ? 48 : 36,
                                height: isSelected ? 48 : 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? a.markerColor : Colors.white,
                                  border: Border.all(
                                    color: a.markerColor,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: a.markerColor.withOpacity(isSelected ? 0.6 : 0.3),
                                      blurRadius: isSelected ? 16 : 6,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    a.emoji,
                                    style: TextStyle(fontSize: isSelected ? 22 : 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── Top Bar ──────────────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack ?? () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E293B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('🗺️  Kandy Explorer',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B))),
                          Text('8 sights • Tap to plan route',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      // Surprise Me button
                      GestureDetector(
                        onTap: _isFindingRoute ? null : _surpriseMe,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _isFindingRoute
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFC6F621), strokeWidth: 2))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🎲', style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 4),
                                    Text('Surprise Me',
                                        style: TextStyle(
                                            color: Color(0xFFC6F621),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Current location badge ────────────────────────────────────────
          Positioned(
            top: 120,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC6F621).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFC6F621)),
                      ),
                      const SizedBox(width: 6),
                      const Text('You are here • Kandy City',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Selected Place Info Sheet ─────────────────────────────────────
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PlaceInfoSheet(
                attraction: _selected!,
                onDismiss: () => setState(() => _selected = null),
              ),
            ),

          // ── Idle hint ─────────────────────────────────────────────────────
          if (_selected == null && !_isFindingRoute)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Text(
                        '📍 Tap a sight to see route & cost • 🎲 Surprise Me for a random pick',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Place Info Bottom Sheet ──────────────────────────────────────────────────
class _PlaceInfoSheet extends StatelessWidget {
  final KandyAttraction attraction;
  final VoidCallback onDismiss;

  const _PlaceInfoSheet({required this.attraction, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      _userLocation,
      attraction.position,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attraction.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attraction.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km from you',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close, color: Colors.white54, size: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      attraction.description,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: attraction.transportIcon,
                          label: attraction.transport,
                          color: attraction.markerColor,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: '⏱️',
                          label: '${attraction.durationMins} min',
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: '💰',
                          label: attraction.costLkr == 0
                              ? 'Free'
                              : 'LKR ${attraction.costLkr}',
                          color: attraction.costLkr == 0
                              ? const Color(0xFF059669)
                              : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // AI Cost breakdown card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFC6F621).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome,
                                  color: Color(0xFFC6F621), size: 14),
                              SizedBox(width: 6),
                              Text('AI Trip Estimate',
                                  style: TextStyle(
                                      color: Color(0xFFC6F621),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _CostRow(label: 'Transport (one-way)',
                              value: attraction.costLkr == 0
                                  ? 'Free'
                                  : 'LKR ${attraction.costLkr}'),
                          _CostRow(
                              label: 'Return trip',
                              value: attraction.costLkr == 0
                                  ? 'Free'
                                  : 'LKR ${attraction.costLkr}'),
                          const Divider(color: Colors.white12, height: 16),
                          _CostRow(
                            label: 'Total (transport only)',
                            value: attraction.costLkr == 0
                                ? 'Free'
                                : 'LKR ${attraction.costLkr * 2}',
                            highlight: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Navigate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC6F621),
                          foregroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Navigation →',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _CostRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: highlight ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: highlight
                      ? const Color(0xFFC6F621)
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
