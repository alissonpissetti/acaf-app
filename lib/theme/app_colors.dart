import 'package:flutter/material.dart';

/// Paleta Movly — cliente final (limão + gradiente céu + roxo estrutural).
abstract final class AppColors {
  static const movlyLime = Color(0xFFCBF74F);
  static const movlyPurple = Color(0xFF8254E4);
  static const movlySky = Color(0xFF89B4E0);
  static const movlyPeriwinkle = Color(0xFF7579E5);
  static const movlyPurpleStrong = Color(0xFF6A3FD0);
  static const movlyPurpleDeep = Color(0xFF2A1B57);
  static const movlyInk = Color(0xFF17142B);

  static const foreground = movlyInk;
  static const foregroundSecondary = Color(0xFF4A4660);
  static const textMuted = Color(0xFF858199);
  static const border = Color(0xFFEBEAF1);
  static const borderStrong = Color(0xFFD9D7E3);

  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF4FAE8);
  static const surfaceSunken = Color(0xFFEFEEF4);
  static const card = Colors.white;

  /// Ação, destaques, barra inferior — energia da marca.
  static const lime = movlyLime;
  static const limeSoft = Color(0x33CBF74F);
  static const onLime = movlyPurpleDeep;

  /// Botões principais e firmeza da marca.
  static const purple = movlyPurple;
  static const purpleSoft = Color(0x1A8254E4);

  static const accent = lime;
  static const primary = purple;
  static const onPrimary = Colors.white;

  /// Compatibilidade com telas legadas (antes: laranja Connect).
  static const orange = lime;
  static const orangeDark = movlyPurpleStrong;
  static const orangeSoft = limeSoft;

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [movlySky, movlyPeriwinkle],
  );

  static const brandGradientDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [movlySky, movlyPeriwinkle, movlyPurple],
    stops: [0, 0.55, 1],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9EC5EA),
      movlySky,
      movlyPeriwinkle,
    ],
  );

  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);

  static const purpleLegacy = foreground;
  static const purpleSoftLegacy = foregroundSecondary;

  static const headerRadius = Radius.circular(0);
}
