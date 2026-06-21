import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Full-bleed hero screen with animated badge, heading, and "Get Started" CTA.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entry;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;
  late Animation<double> _headFade;
  late Animation<Offset> _headSlide;
  late Animation<double> _subFade;
  late Animation<Offset> _subSlide;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _badgeFade = _fade(0.3, 0.6);
    _badgeSlide = _slide(0.3, 0.6);
    _headFade = _fade(0.45, 0.75);
    _headSlide = _slide(0.45, 0.75);
    _subFade = _fade(0.55, 0.85);
    _subSlide = _slide(0.55, 0.85);
    _btnFade = _fade(0.65, 0.95);
    _btnSlide = _slide(0.65, 0.95);
  }

  Animation<double> _fade(double start, double end) =>
      CurvedAnimation(
        parent: _entry,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entry,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed hero image
        Image.asset(
          'assets/images/hostess.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF004953)), // Teal background fallback
        ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x0D000000),
                Color(0x26000000),
                Color(0xBF000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Top status bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 52),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRAVEL BOKKA',
                  style: AyuText.label(
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                    weight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 16,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated badge
                FadeTransition(
                  opacity: _badgeFade,
                  child: SlideTransition(
                    position: _badgeSlide,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004953).withOpacity(0.8), // Teal Dim
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: const Color(0xFF00B0B9).withOpacity(0.4)), // Bright Teal
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulseDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Your AI Travel Companion',
                            style: AyuText.label(
                              color: const Color(0xFFFDB913), // Gold
                              size: 12,
                              weight: FontWeight.w600,
                              letterSpacing: 0.04 * 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Heading
                FadeTransition(
                  opacity: _headFade,
                  child: SlideTransition(
                    position: _headSlide,
                    child: Text('Ayubowan.',
                        style: AyuText.display(color: AyuColors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                FadeTransition(
                  opacity: _subFade,
                  child: SlideTransition(
                    position: _subSlide,
                    child: Text(
                      'Your Travel Guide in\nYour Pocket.',
                      style: AyuText.body(
                        color: Colors.white.withOpacity(0.85),
                        size: 16.8,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // CTA button
                FadeTransition(
                  opacity: _btnFade,
                  child: SlideTransition(
                    position: _btnSlide,
                    child: _GetStartedButton(onTap: widget.onGetStarted),
                  ),
                ),
                const SizedBox(height: 16),
                // Hint text
                Center(
                  child: Text(
                    'Explore Sri Lanka — protected & guided',
                    style: AyuText.label(
                      color: Colors.white.withOpacity(0.5),
                      size: 12,
                    ),
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

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFDB913), // Gold
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
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
      duration: const Duration(milliseconds: 100),
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
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xA60F140A),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Get Started', style: AyuText.button()),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDB913), // Gold
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 18, color: Color(0xFF004953)), // Teal Navy
              ),
            ],
          ),
        ),
      ),
    );
  }
}
