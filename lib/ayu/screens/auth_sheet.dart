import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

/// Shows the login bottom sheet as a modal.
Future<void> showAuthSheet(
  BuildContext context, {
  required VoidCallback onLogin,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => _AuthSheetContent(onLogin: onLogin),
  );
}

class _AuthSheetContent extends StatefulWidget {
  const _AuthSheetContent({required this.onLogin});
  final VoidCallback onLogin;

  @override
  State<_AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<_AuthSheetContent> {
  bool _showPassword = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle pill
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AyuColors.divider,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28).copyWith(top: 16, bottom: 32),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text('Ready to explore Sri Lanka?',
                        style: AyuText.h2(color: AyuColors.navy).copyWith(
                            fontSize: 26.4, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to unlock your AI travel companion.',
                      style: AyuText.body(
                          color: AyuColors.textSubtle, size: 14.4),
                    ),
                    const SizedBox(height: 28),
                    // Email field
                    _InputField(
                      controller: _emailCtrl,
                      hint: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    // Password field
                    _InputField(
                      controller: _passCtrl,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showPassword,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: AyuColors.textSubtle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    _TapButton(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onLogin();
                      },
                      color: AyuColors.lime,
                      child: Center(
                        child: Text('Login',
                            style: AyuText.button(color: AyuColors.navy)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: AyuColors.borderLight, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with',
                              style: AyuText.label(
                                  color: AyuColors.textPlaceholder, size: 12)),
                        ),
                        Expanded(
                            child: Divider(
                                color: AyuColors.borderLight, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Google button
                    _TapButton(
                      onTap: () {},
                      color: Colors.transparent,
                      border: Border.all(color: AyuColors.divider, width: 1.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleIcon(),
                          const SizedBox(width: 12),
                          Text('Continue with Google',
                              style: AyuText.body(
                                  size: 15.2,
                                  weight: FontWeight.w600,
                                  color: AyuColors.navy)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign up prompt
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: AyuText.label(
                              color: AyuColors.textPlaceholder, size: 12),
                          children: [
                            const TextSpan(text: 'No account? '),
                            TextSpan(
                              text: 'Sign up free',
                              style: AyuText.label(
                                color: AyuColors.sageDeep,
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F1ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 15, color: AyuColors.navy),
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
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AyuColors.inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AyuColors.textSubtle),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AyuText.body(
                    size: 14, color: AyuColors.textPlaceholder),
              ),
              style: AyuText.body(size: 14, color: AyuColors.navy),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}

class _TapButton extends StatefulWidget {
  const _TapButton({
    required this.onTap,
    required this.color,
    required this.child,
    this.border,
  });
  final VoidCallback onTap;
  final Color color;
  final Widget child;
  final BoxBorder? border;

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton>
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
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(50),
            border: widget.border,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    // Simplified Google "G" using coloured arcs
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final sweeps = [1.5708, 1.5708, 1.5708, 1.5708];
    final starts = [4.712, 0.0, 1.5708, 3.1416];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r),
        starts[i],
        sweeps[i],
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = size.width * 0.35
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
