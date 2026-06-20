import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ayu_colors.dart';

/// AYU typography helpers — all using Plus Jakarta Sans.
class AyuText {
  AyuText._();

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle display({Color color = AyuColors.white, double size = 38.4}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
        letterSpacing: -0.02 * size,
      );

  // ── Headings ─────────────────────────────────────────────────────────────
  static TextStyle h1({Color color = AyuColors.navy}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24.8,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle h2({Color color = AyuColors.navy}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 19.2,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle h3({Color color = AyuColors.navy}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16.8,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle body({
    Color color = AyuColors.navy,
    double size = 14.0,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  // ── Label / caption ───────────────────────────────────────────────────────
  static TextStyle label({
    Color color = AyuColors.textMuted,
    double size = 12.0,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // ── Button ────────────────────────────────────────────────────────────────
  static TextStyle button({Color color = AyuColors.navy, double size = 16.0}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── Uppercase section label ───────────────────────────────────────────────
  static TextStyle sectionLabel({Color color = AyuColors.sage}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.06 * 12.5,
      );

  // ── Chip text ─────────────────────────────────────────────────────────────
  static TextStyle chip({Color color = AyuColors.navy, bool active = false}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13.0,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: color,
      );
}
