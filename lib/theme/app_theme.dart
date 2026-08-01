import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = GoogleFonts.interTextTheme();

    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.orangeDark,
      onSecondary: Colors.white,
      tertiary: AppColors.foreground,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.orange),
      textTheme: base.copyWith(
        headlineMedium: AppTypography.pageTitle,
        titleLarge: AppTypography.sectionTitle,
        titleMedium: AppTypography.sectionTitle.copyWith(fontSize: 16),
        titleSmall: AppTypography.cardTitle.copyWith(fontSize: 15),
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodyMuted,
        bodySmall: AppTypography.caption,
        labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          letterSpacing: -0.2,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.orange, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.orange),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        hintStyle: AppTypography.bodyMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1,
          color: AppColors.textMuted,
          backgroundColor: AppColors.surface,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          backgroundColor: AppColors.surface,
        ),
        border: _inputOutlineBorder(AppColors.border),
        enabledBorder: _inputOutlineBorder(AppColors.border),
        disabledBorder: _inputOutlineBorder(AppColors.border),
        errorBorder: _inputOutlineBorder(AppColors.error),
        focusedBorder: _inputOutlineBorder(AppColors.orange),
        focusedErrorBorder: _inputOutlineBorder(AppColors.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.orange,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.foreground),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.orangeSoft,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.orange : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.orange : AppColors.textMuted,
          );
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.orange;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
    );
  }

  static OutlineInputBorder _inputOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      gapPadding: 8,
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}
