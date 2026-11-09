import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = GoogleFonts.figtreeTextTheme();

    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.lime,
      onSecondary: AppColors.onLime,
      tertiary: AppColors.movlyPeriwinkle,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surfaceMuted,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      textTheme: base.copyWith(
        headlineMedium: AppTypography.pageTitle,
        titleLarge: AppTypography.sectionTitle,
        titleMedium: AppTypography.sectionTitle.copyWith(fontSize: 16),
        titleSmall: AppTypography.cardTitle.copyWith(fontSize: 15),
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodyMuted,
        bodySmall: AppTypography.caption,
        labelLarge: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
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
          borderRadius: BorderRadius.circular(20),
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.figtree(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.figtree(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        hintStyle: AppTypography.bodyMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: GoogleFonts.figtree(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1,
          color: AppColors.textMuted,
          backgroundColor: AppColors.surface,
        ),
        labelStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          backgroundColor: AppColors.surface,
        ),
        border: _inputOutlineBorder(AppColors.border),
        enabledBorder: _inputOutlineBorder(AppColors.border),
        disabledBorder: _inputOutlineBorder(AppColors.border),
        errorBorder: _inputOutlineBorder(AppColors.error),
        focusedBorder: _inputOutlineBorder(AppColors.primary),
        focusedErrorBorder: _inputOutlineBorder(AppColors.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.lime,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.onLime),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.lime,
        indicatorColor: AppColors.onLime.withValues(alpha: 0.14),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.figtree(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? AppColors.onLime
                : AppColors.onLime.withValues(alpha: 0.72),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? AppColors.onLime
                : AppColors.onLime.withValues(alpha: 0.72),
          );
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
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
