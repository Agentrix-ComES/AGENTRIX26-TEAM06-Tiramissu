import 'package:flutter/material.dart';

/// AYU design-system colour tokens — mirrors the React CSS values exactly.
class AyuColors {
  AyuColors._();

  // ── Primary accent ────────────────────────────────────────────────────────
  static const Color lime = Color(0xFFD9F974); // primary CTA / active state
  static const Color limeDim = Color(0x33D9F974); // 20 % lime overlay

  // ── Dark neutrals ─────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF1E293B); // primary text / dark bg
  static const Color navyDeep = Color(0xFF2D4A30); // profile hero gradient end

  // ── Sage / green system ───────────────────────────────────────────────────
  static const Color sage = Color(0xFF8FA05A); // location pill, section icons
  static const Color sageDeep = Color(0xFF5A8A1E); // links, map view
  static const Color sageBg = Color(0xFFF4F5F0); // page background
  static const Color sageLightBg = Color(0xFFF0F5E8); // icon container bg
  static const Color sageAccent = Color(0xFFA8E6CF); // Sight-Glass card accent

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFFF4D4D);
  static const Color dangerBg = Color(0xFFFFF5F5);
  static const Color dangerLight = Color(0xFFFFE5E5);
  static const Color success = Color(0xFF22A06B);
  static const Color successBg = Color(0xFFF0FFF8);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBF0);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF6366F1);
  static const Color infoBg = Color(0xFFF0F5FF);
  static const Color infoLight = Color(0xFFE0E7FF);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xF7FFFFFF); // 97 % white
  static const Color borderLight = Color(0xFFE8EAE5);
  static const Color borderLighter = Color(0xFFECEEE9);
  static const Color textMuted = Color(0xFF8A8F85);
  static const Color textPlaceholder = Color(0xFFB5B8B2);
  static const Color textSubtle = Color(0xFF9FA49A);
  static const Color textLight = Color(0xFFC5C8C1);
  static const Color divider = Color(0xFFE2E4DF);
  static const Color inputBg = Color(0xFFF2F3EF);

  // ── Overlays ─────────────────────────────────────────────────────────────
  static const Color overlayDark = Color(0x59000000); // ~35 %
  static const Color overlayMid = Color(0x26000000);  // ~15 %
  static const Color overlayLight = Color(0x0D000000); // ~5 %

  // ── Star / rating ─────────────────────────────────────────────────────────
  static const Color star = Color(0xFFF5B731);
}
