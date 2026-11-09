import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografia Movly — display (Unbounded) + corpo (Figtree), alinhado ao portal web.
abstract final class AppTypography {
  static TextStyle get display => GoogleFonts.unbounded(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.6,
        color: AppColors.foreground,
      );

  static TextStyle get pageTitle => display;

  static TextStyle get pageSubtitle => GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textMuted,
      );

  static TextStyle get sectionTitle => GoogleFonts.figtree(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
        color: AppColors.foreground,
      );

  static TextStyle get cardTitle => GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
        color: AppColors.foreground,
      );

  static TextStyle get body => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get bodyMuted => GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.3,
        color: AppColors.textMuted,
      );

  static TextStyle get tagline => GoogleFonts.unbounded(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: -0.2,
        color: AppColors.movlyPurpleDeep,
      );
}

abstract final class AppSpacing {
  static const pageX = 20.0;
  static const section = 32.0;
  static const block = 16.0;
  static const item = 12.0;
  static const tight = 8.0;
}
