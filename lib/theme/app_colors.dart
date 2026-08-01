import 'package:flutter/material.dart';

/// Paleta base neutra com acento laranja da marca (#E8881C).
abstract final class AppColors {
  static const foreground = Color(0xFF1C1C1E);
  static const foregroundSecondary = Color(0xFF3A3A3C);
  static const textMuted = Color(0xFF8E8E93);
  static const border = Color(0xFFE5E5EA);
  static const borderStrong = Color(0xFFD1D1D6);

  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF7F7F8);
  static const card = Colors.white;

  /// Cor de destaque (detalhes, ícones ativos, seleção, preços).
  static const orange = Color(0xFFE8881C);
  static const orangeDark = Color(0xFFC97416);
  static const orangeSoft = Color(0x1AE8881C);

  static const accent = orange;

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF0A035), orange],
  );

  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);

  static const purple = foreground;
  static const purpleSoft = foregroundSecondary;

  static const headerRadius = Radius.circular(0);
}
