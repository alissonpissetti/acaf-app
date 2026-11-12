import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de marca expostos via [ThemeExtension] (gradientes, papéis de cor).
@immutable
class MovlyThemeTokens extends ThemeExtension<MovlyThemeTokens> {
  const MovlyThemeTokens({
    required this.brandGradient,
    required this.brandGradientDiagonal,
    required this.heroGradient,
    required this.lime,
    required this.onLime,
    required this.ink,
    required this.purple,
    required this.purpleDeep,
    required this.surfaceMuted,
    required this.ecosystemAccent,
  });

  final LinearGradient brandGradient;
  final LinearGradient brandGradientDiagonal;
  final LinearGradient heroGradient;
  final Color lime;
  final Color onLime;
  final Color ink;
  final Color purple;
  final Color purpleDeep;
  final Color surfaceMuted;

  /// Laranja operacional (admin / alertas de ação) — alinhado a PREMISSAS-VISUAIS.
  final Color ecosystemAccent;

  static const light = MovlyThemeTokens(
    brandGradient: AppColors.brandGradient,
    brandGradientDiagonal: AppColors.brandGradientDiagonal,
    heroGradient: AppColors.heroGradient,
    lime: AppColors.lime,
    onLime: AppColors.onLime,
    ink: AppColors.foreground,
    purple: AppColors.purple,
    purpleDeep: AppColors.movlyPurpleDeep,
    surfaceMuted: AppColors.surfaceMuted,
    ecosystemAccent: Color(0xFFE8881C),
  );

  @override
  MovlyThemeTokens copyWith({
    LinearGradient? brandGradient,
    LinearGradient? brandGradientDiagonal,
    LinearGradient? heroGradient,
    Color? lime,
    Color? onLime,
    Color? ink,
    Color? purple,
    Color? purpleDeep,
    Color? surfaceMuted,
    Color? ecosystemAccent,
  }) {
    return MovlyThemeTokens(
      brandGradient: brandGradient ?? this.brandGradient,
      brandGradientDiagonal: brandGradientDiagonal ?? this.brandGradientDiagonal,
      heroGradient: heroGradient ?? this.heroGradient,
      lime: lime ?? this.lime,
      onLime: onLime ?? this.onLime,
      ink: ink ?? this.ink,
      purple: purple ?? this.purple,
      purpleDeep: purpleDeep ?? this.purpleDeep,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ecosystemAccent: ecosystemAccent ?? this.ecosystemAccent,
    );
  }

  @override
  MovlyThemeTokens lerp(MovlyThemeTokens? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

extension MovlyThemeContext on BuildContext {
  MovlyThemeTokens get movlyTokens =>
      Theme.of(this).extension<MovlyThemeTokens>() ?? MovlyThemeTokens.light;
}
