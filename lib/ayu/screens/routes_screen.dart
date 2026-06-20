import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import '../services/api_service.dart';

const _suggested = [
  _SuggestData(name: 'Temple of the Sacred Tooth Relic', sub: '0.5 km away • Temple', tag: 'Popular', tagColor: AyuColors.lime),
  _SuggestData(name: 'Kandy Lake', sub: '0.2 km away • Park', tag: 'Scenic', tagColor: AyuColors.sageAccent),
  _SuggestData(name: 'Udawatta Kele Sanctuary', sub: '1.5 km away • Nature', tag: 'Must-see', tagColor: Color(0xFFFFD6A5)),
];

class _SuggestData {
  final String name, sub, tag;
  final Color tagColor;
  const _SuggestData({required this.name, required this.sub, required this.tag, required this.tagColor});
}

const _turns = [
  _Turn(dir: 'straight', label: 'Head east on Dalada Vidiya', dist: '0.3 km'),
  _Turn(dir: 'right', label: 'Turn right toward Kandy Lake', dist: '0.1 km'),
  _Turn(dir: 'straight', label: 'Continue along the lake path', dist: '0.1 km'),
  _Turn(dir: 'arrive', label: 'Arrive at Temple of the Sacred Tooth Relic', dist: ''),
];

class _Turn {
  final String dir, label, dist;
  const _Turn({required this.dir, required this.label, required this.dist});
}

/// Routes screen — aerial map background, dashed route overlay, search panel, bottom panel.
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen>
    with SingleTickerProviderStateMixin {
  bool _navigating = false;
  int _activeMode = 0;
  int _currentStep = 0;
  String _destination = 'Temple of the Sacred Tooth Relic';
  bool _showSuggestions = false;
  bool _isLoading = false;
  String? _apiError;
  final _destCtrl = TextEditingController(text: 'Temple of the Sacred Tooth Relic');
  final _focusNode = FocusNode();

  // Animated dashed-line offset for route
  late AnimationController _dashAnim;

  @override
  void initState() {
    super.initState();
    _dashAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _dashAnim.dispose();
    _destCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Map background
        ColorFiltered(
          colorFilter: ColorFilter.matrix([
            0.75, 0, 0, 0, 0,
            0, 0.75, 0, 0, 0,
            0, 0, 0.75, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Image.network(
            'https://images.unsplash.com/photo-1740812517495-812e90ca01b1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFFD8E4D0)),
          ),
        ),
        // Tint overlay
        Container(color: const Color(0x40F0F5EB)),
        // Route SVG overlay
        AnimatedBuilder(
          animation: _dashAnim,
          builder: (_, __) => CustomPaint(
            painter: _RoutePainter(dashOffset: _dashAnim.value * 36),
          ),
        ),
        // Back button
        Positioned(
          top: 40,
          left: 20,
          child: _MapButton(
            icon: Icons.arrow_back,
            onTap: _navigating ? () => setState(() => _navigating = false) : widget.onBack,
          ),
        ),
        // Recenter button
        Positioned(
          top: 40,
          right: 20,
          child: _MapButton(
            icon: Icons.my_location_rounded,
            color: AyuColors.sageDeep,
          ),
        ),
        // Search panel (not navigating)
        if (!_navigating)
          Positioned(
            top: 96,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Origin/Dest panel
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Origin
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AyuColors.navy, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('My Location — Kandy City Center',
                                  style: AyuText.body(
                                      color: AyuColors.textMuted, size: 14, weight: FontWeight.w500)),
                            ),
                            const Icon(Icons.my_location_rounded,
                                size: 14, color: AyuColors.sageDeep),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: const Color(0xFFF0F1EC)),
                      // Destination
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: AyuColors.lime),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _destCtrl,
                                focusNode: _focusNode,
                                style: AyuText.body(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: AyuColors.navy),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Where to?',
                                  hintStyle: AyuText.body(
                                      size: 14,
                                      color: AyuColors.textSubtle),
                                ),
                                onChanged: (v) =>
                                    setState(() => _destination = v),
                              ),
                            ),
                            const Icon(Icons.search_rounded,
                                size: 14, color: AyuColors.textSubtle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Suggestions dropdown
                if (_showSuggestions) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: _suggested.asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        return GestureDetector(
                          onTap: () {
                            _destCtrl.text = s.name;
                            setState(() {
                              _destination = s.name;
                              _showSuggestions = false;
                            });
                            _focusNode.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: i < _suggested.length - 1
                                  ? const Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFF0F1EC)))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AyuColors.sageBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.location_on,
                                      size: 14, color: AyuColors.sageDeep),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: AyuText.body(
                                              size: 13.6,
                                              weight: FontWeight.w700)),
                                      Text(s.sub,
                                          style: AyuText.label(
                                              color: AyuColors.textSubtle,
                                              size: 11.5)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: s.tagColor,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(s.tag,
                                      style: AyuText.label(
                                          color: AyuColors.navy,
                                          size: 11.5,
                                          weight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        // Live navigation header
        if (_navigating)
          Positioned(
            top: 96,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AyuColors.navy,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AyuColors.lime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _turns[_currentStep].dir == 'right'
                              ? Icons.turn_right_rounded
                              : _turns[_currentStep].dir == 'left'
                                  ? Icons.turn_left_rounded
                                  : _turns[_currentStep].dir == 'arrive'
                                      ? Icons.location_on_rounded
                                      : Icons.navigation_rounded,
                          size: 18,
                          color: AyuColors.navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_turns[_currentStep].label,
                                style: AyuText.body(
                                    color: AyuColors.white,
                                    size: 15.2,
                                    weight: FontWeight.w700)),
                            if (_turns[_currentStep].dist.isNotEmpty)
                              Text(_turns[_currentStep].dist,
                                  style: AyuText.label(
                                      color: AyuColors.lime,
                                      size: 12.8,
                                      weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_currentStep < _turns.length - 1) {
                            setState(() => _currentStep++);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AyuColors.lime.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right,
                              size: 16, color: AyuColors.lime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Step progress dots
                  Row(
                    children: List.generate(
                      _turns.length,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? AyuColors.lime
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Bottom panel
        Positioned(
          bottom: 0,
          left: 12,
          right: 12,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AyuColors.divider,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      // Dest label + ETA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_destination,
                                    style: AyuText.h3()),
                                if (_apiError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(_apiError!,
                                        style: AyuText.label(color: AyuColors.danger, size: 12)),
                                  ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 11, color: AyuColors.star),
                                    const SizedBox(width: 3),
                                    Text('4.8 • Temple • Must-see',
                                        style: AyuText.label(
                                            color: AyuColors.textSubtle,
                                            size: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('18 min',
                                  style: AyuText.h3()),
                              Text('4.2 km away',
                                  style: AyuText.label(
                                      color: AyuColors.sage,
                                      size: 12,
                                      weight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Transport mode selector
                      Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: '18 min',
                              sub: '₨1,200',
                              icon: Icons.directions_car_rounded,
                              active: _activeMode == 0,
                              onTap: () => setState(() => _activeMode = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModeButton(
                              label: '52 min',
                              sub: 'Free',
                              icon: Icons.directions_walk_rounded,
                              active: _activeMode == 1,
                              onTap: () => setState(() => _activeMode = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ETA strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AyuColors.sageBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: AyuColors.sage),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: AyuText.body(
                                    color: const Color(0xFF64748B),
                                    size: 12.8),
                                children: [
                                  const TextSpan(text: 'ETA: '),
                                  TextSpan(
                                    text: '2:34 PM',
                                    style: AyuText.body(
                                        size: 12.8,
                                        weight: FontWeight.w700,
                                        color: AyuColors.navy),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AyuColors.lime,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text('Fair fare verified ✓',
                                  style: AyuText.label(
                                      color: AyuColors.navy,
                                      size: 11.2,
                                      weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CTA
                      GestureDetector(
                        onTap: () async {
                          if (_navigating) {
                            setState(() => _navigating = false);
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                            _apiError = null;
                          });
                          
                          final resp = await ApiService.pivotRoute(
                            origin: 'Colombo 3',
                            destination: _destination,
                            blockedTransportMode: _activeMode == 0 ? 'Train' : 'Bus',
                          );

                          setState(() {
                            _isLoading = false;
                            if (resp.success) {
                              _navigating = true;
                            } else {
                              _apiError = resp.error ?? 'Failed to pivot route';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _navigating
                                ? AyuColors.danger
                                : AyuColors.lime,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AyuColors.navy),
                                )
                              else if (!_navigating) ...[
                                const Icon(Icons.navigation_rounded,
                                    size: 17, color: AyuColors.navy),
                                const SizedBox(width: 10),
                              ],
                              if (!_isLoading)
                                Text(
                                  _navigating
                                      ? 'End Navigation'
                                      : 'Start Navigation',
                                  style: AyuText.button(
                                      color: _navigating
                                          ? AyuColors.white
                                          : AyuColors.navy),
                                ),
                            ],
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
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 17, color: color ?? AyuColors.navy),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label, sub;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AyuColors.navy : AyuColors.sageBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15, color: active ? AyuColors.lime : AyuColors.textSubtle),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AyuText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: active ? AyuColors.white : AyuColors.navy)),
                Text(sub,
                    style: AyuText.label(
                        color: active ? AyuColors.lime : AyuColors.textSubtle,
                        size: 10.4,
                        weight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the route on the map.
class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.dashOffset});
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale path points from 390×844 design canvas
    final sx = size.width / 390;
    final sy = size.height / 844;

    // Shadow
    _drawPath(canvas, sx, sy,
        color: Colors.black.withOpacity(0.15), width: 10, dashPattern: null);
    // Main dashed line
    _drawPath(canvas, sx, sy,
        color: AyuColors.lime, width: 6, dashPattern: [12.0, 6.0], offset: dashOffset);

    // Origin dot
    final origin = Offset(195 * sx, 680 * sy);
    canvas.drawCircle(origin, 10 * sx, Paint()..color = AyuColors.white);
    canvas.drawCircle(
        origin,
        10 * sx,
        Paint()
          ..color = AyuColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * sx);
    canvas.drawCircle(origin, 5 * sx, Paint()..color = AyuColors.navy);

    // Destination dot + ring
    final dest = Offset(210 * sx, 232 * sy);
    canvas.drawCircle(
        dest,
        14 * sx,
        Paint()
          ..color = AyuColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * sx);
    canvas.drawCircle(dest, 14 * sx, Paint()..color = AyuColors.lime);
    canvas.drawCircle(dest, 6 * sx, Paint()..color = AyuColors.navy);
  }

  void _drawPath(Canvas canvas, double sx, double sy,
      {required Color color,
      required double width,
      List<double>? dashPattern,
      double offset = 0}) {
    final path = Path()
      ..moveTo(195 * sx, 680 * sy)
      ..quadraticBezierTo(195 * sx, 580 * sy, 240 * sx, 500 * sy)
      ..quadraticBezierTo(280 * sx, 430 * sy, 260 * sx, 350 * sy)
      ..quadraticBezierTo(245 * sx, 290 * sy, 210 * sx, 240 * sy);

    final paint = Paint()
      ..color = color
      ..strokeWidth = width * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (dashPattern == null) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashedPath(canvas, path, paint, dashPattern, offset * sx);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      List<double> dashPattern, double offset) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = offset % (dashPattern[0] + dashPattern[1]);
      bool drawing = true;
      while (distance < metric.length) {
        final len = drawing ? dashPattern[0] : dashPattern[1];
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.dashOffset != dashOffset;
}
