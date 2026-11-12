import 'package:flutter/material.dart';

import '../branding/brand_assets.dart';
import '../branding/movly_brand.dart';

enum BrandLogoVariant { purple, lime, white, lockupOnLime, gradient }

/// Lockup **movly. by ACAF** — raster do manual `movly-by-acaf.app.pdf` (sem texto manual de submarca).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 44,
    this.variant = BrandLogoVariant.purple,
  });

  final double height;
  final BrandLogoVariant variant;

  /// Altura total do lockup (útil para alinhar toolbars).
  static double totalHeight(double lockupHeight, {bool includesSubbrand = false}) =>
      lockupHeight;

  static String _assetFor(BrandLogoVariant v) {
    switch (v) {
      case BrandLogoVariant.purple:
      case BrandLogoVariant.lockupOnLime:
        return BrandAssets.movlyLogoPurpleOnLime;
      case BrandLogoVariant.white:
      case BrandLogoVariant.lime:
        return BrandAssets.movlyLogoLimeOnPurple;
      case BrandLogoVariant.gradient:
        return BrandAssets.movlyLogoLimeOnGradient;
    }
  }

  /// Largura proporcional às dimensões nativas de cada arte (manual p. 3).
  static double _widthFor(BrandLogoVariant v, double h) {
    switch (v) {
      case BrandLogoVariant.purple:
      case BrandLogoVariant.lockupOnLime:
        return h * (813 / 414);
      case BrandLogoVariant.white:
      case BrandLogoVariant.lime:
        return h * (791 / 386);
      case BrandLogoVariant.gradient:
        return h * (791 / 387);
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = _assetFor(variant);
    final w = _widthFor(variant, height);

    return Semantics(
      label: MovlyBrand.semanticLabel,
      child: SizedBox(
        width: w,
        height: height,
        child: Image.asset(
          src,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
