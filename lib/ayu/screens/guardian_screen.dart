import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Guardian screen — camera AR overlay, mic pulse rings, animated scam alert card.
class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen>
    with TickerProviderStateMixin {
  bool _scamVisible = false;
  late AnimationController _pulse0, _pulse1, _pulse2;
  late AnimationController _scamSlide;
  late Animation<Offset> _scamOffset;

  @override
  void initState() {
    super.initState();

    // Three staggered pulse rings
    _pulse0 = _makePulse(0);
    _pulse1 = _makePulse(500);
    _pulse2 = _makePulse(1000);

    _scamSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scamOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _scamSlide, curve: Curves.easeOutBack));

    // Auto-trigger after 3.5 s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _scamVisible = true);
        _scamSlide.forward();
      }
    });
  }

  AnimationController _makePulse(int delayMs) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) ctrl.repeat();
    });
    return ctrl;
  }

  @override
  void dispose() {
    _pulse0.dispose();
    _pulse1.dispose();
    _pulse2.dispose();
    _scamSlide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            _scamVisible
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            BlendMode.srcOver,
          ),
          child: Image.network(
            'https://images.unsplash.com/photo-1772729629782-558d884c5d96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A2A1A)),
          ),
        ),
        // Top vignette
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8C000000), Colors.transparent],
              ),
            ),
          ),
        ),
        // Scan-line overlay (only when no scam alert)
        if (!_scamVisible)
          _ScanLinesOverlay(),
        // Back button
        Positioned(
          top: 40,
          left: 20,
          child: _CircleButton(
            icon: Icons.arrow_back,
            onTap: widget.onBack,
          ),
        ),
        // "GUARDIAN ACTIVE" label
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 13, color: AyuColors.lime),
                  const SizedBox(width: 6),
                  Text('GUARDIAN ACTIVE',
                      style: AyuText.label(
                          color: AyuColors.white,
                          size: 12,
                          weight: FontWeight.w700,
                          letterSpacing: 0.04 * 12)),
                  const SizedBox(width: 6),
                  _PulsingDot(),
                ],
              ),
            ),
          ),
        ),
        // Top AR info cards
        Positioned(
          top: 96,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(child: _ArCard(label: 'DISTANCE', value: '1.2 km', sub: 'Fort Station', icon: Icons.navigation_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _ArCard(label: 'LOCATION', value: 'Pettah', sub: 'Colombo 11', icon: Icons.location_on_rounded)),
              const SizedBox(width: 10),
              Expanded(
                child: _ArCard(
                  label: 'FAIR FARE',
                  value: '₨1,200',
                  sub: 'Tuk avg.',
                  icon: Icons.shield_rounded,
                  accent: true,
                ),
              ),
            ],
          ),
        ),
        // Mic pulse rings (only when no scam)
        if (!_scamVisible)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _MicPulseRings(ctrl0: _pulse0, ctrl1: _pulse1, ctrl2: _pulse2),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text('Listening for unusual pricing…',
                      style: AyuText.label(
                          color: AyuColors.white,
                          size: 12,
                          weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        // Scam alert bottom card
        if (_scamVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _scamOffset,
              child: _ScamAlertCard(
                onDecline: () {
                  _scamSlide.reverse().then((_) {
                    if (mounted) setState(() => _scamVisible = false);
                  });
                },
                onFairPrice: () {
                  _scamSlide.reverse().then((_) {
                    if (mounted) setState(() => _scamVisible = false);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AyuColors.white),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: AyuColors.lime, shape: BoxShape.circle)),
      );
}

class _ArCard extends StatelessWidget {
  const _ArCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.accent = false,
  });
  final String label, value, sub;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent
              ? AyuColors.lime.withOpacity(0.2)
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent
                ? AyuColors.lime.withOpacity(0.4)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: AyuColors.lime),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AyuText.label(
                      color: accent
                          ? AyuColors.lime
                          : Colors.white.withOpacity(0.7),
                      size: 10,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: AyuText.body(
                    size: 18.4, weight: FontWeight.w800, color: AyuColors.white)),
            Text(sub,
                style: AyuText.label(color: Colors.white.withOpacity(0.6), size: 10)),
          ],
        ),
      ),
    );
  }
}

class _MicPulseRings extends StatelessWidget {
  const _MicPulseRings({required this.ctrl0, required this.ctrl1, required this.ctrl2});
  final AnimationController ctrl0, ctrl1, ctrl2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseRing(ctrl: ctrl0, maxRadius: 58),
          _PulseRing(ctrl: ctrl1, maxRadius: 48),
          _PulseRing(ctrl: ctrl2, maxRadius: 38),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AyuColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, size: 22, color: AyuColors.navy),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.ctrl, required this.maxRadius});
  final AnimationController ctrl;
  final double maxRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return CustomPaint(
          size: Size(maxRadius * 2, maxRadius * 2),
          painter: _RingPainter(
            radius: 20 + (maxRadius - 20) * t,
            opacity: (1.0 - t) * 0.6,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.radius, required this.opacity});
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..color = AyuColors.lime.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.opacity != opacity;
}

class _ScanLinesOverlay extends StatefulWidget {
  @override
  State<_ScanLinesOverlay> createState() => _ScanLinesOverlayState();
}

class _ScanLinesOverlayState extends State<_ScanLinesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0, end: 0.06).animate(_ctrl),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(''), // empty — drawn via shader
            ),
          ),
          child: CustomPaint(painter: _ScanLinePainter()),
        ),
      );
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AyuColors.lime.withOpacity(0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _ScamAlertCard extends StatelessWidget {
  const _ScamAlertCard({required this.onDecline, required this.onFairPrice});
  final VoidCallback onDecline;
  final VoidCallback onFairPrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AyuColors.danger.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AyuColors.danger.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AyuColors.danger.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AyuColors.danger),
                  const SizedBox(width: 10),
                  Text('SCAM ALERT DETECTED',
                      style: AyuText.label(
                          color: AyuColors.danger,
                          size: 13.6,
                          weight: FontWeight.w800,
                          letterSpacing: 0.04 * 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AyuColors.danger.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: AyuColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Overpriced Fare Detected',
                      style: AyuText.body(
                          size: 16.8, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: AyuText.body(
                          color: const Color(0xFF64748B), size: 14),
                      children: [
                        const TextSpan(text: 'Driver quoted '),
                        TextSpan(
                          text: 'LKR 5,000',
                          style: AyuText.body(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AyuColors.danger),
                        ),
                        const TextSpan(
                            text: ' for this route. The local average for 1.2 km is only '),
                        TextSpan(
                          text: 'LKR 1,200',
                          style: AyuText.body(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AyuColors.success),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price comparison bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _PriceCol(label: 'QUOTED', value: '₨5,000', color: AyuColors.danger),
                        Container(width: 1, height: 32, color: AyuColors.divider),
                        _PriceCol(label: 'FAIR PRICE', value: '₨1,200', color: AyuColors.success),
                        Container(width: 1, height: 32, color: AyuColors.divider),
                        _PriceCol(label: 'OVERCHARGE', value: '4.2×', color: AyuColors.danger),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Decline',
                          icon: Icons.thumb_down_rounded,
                          color: AyuColors.white,
                          bgColor: AyuColors.danger,
                          onTap: onDecline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Fair Price',
                          icon: Icons.check_circle_outline_rounded,
                          color: AyuColors.success,
                          bgColor: Colors.transparent,
                          border: Border.all(
                              color: AyuColors.success, width: 2),
                          onTap: onFairPrice,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCol extends StatelessWidget {
  const _PriceCol({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AyuText.label(
                color: AyuColors.textSubtle, size: 11.2, weight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: AyuText.body(size: 19.2, weight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.border,
  });
  final String label;
  final IconData icon;
  final Color color, bgColor;
  final BoxBorder? border;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _p;
  @override
  void initState() {
    super.initState();
    _p = AnimationController(vsync: this, lowerBound: 0.96, upperBound: 1.0, value: 1.0, duration: const Duration(milliseconds: 100));
  }
  @override
  void dispose() { _p.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _p.reverse(),
        onTapUp: (_) { _p.forward(); widget.onTap(); },
        onTapCancel: () => _p.forward(),
        child: AnimatedBuilder(
          animation: _p,
          builder: (_, child) => Transform.scale(scale: _p.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(50),
              border: widget.border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 15, color: widget.color),
                const SizedBox(width: 8),
                Text(widget.label,
                    style: AyuText.body(
                        size: 14.4, weight: FontWeight.w700, color: widget.color)),
              ],
            ),
          ),
        ),
      );
}
