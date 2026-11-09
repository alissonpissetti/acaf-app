import 'package:flutter/material.dart';

import '../branding/brand_assets.dart';

enum BrandLogoVariant { purple, lime, white }

/// Lockup **movly. by ACAF** (PNG do manual).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 44,
    this.variant = BrandLogoVariant.purple,
  });

  final double height;
  final BrandLogoVariant variant;

  static String _assetFor(BrandLogoVariant v) {
    switch (v) {
      case BrandLogoVariant.purple:
        return BrandAssets.movlyLogoPurpleOnLime;
      case BrandLogoVariant.lime:
        return BrandAssets.movlyLogoLimeOnPurple;
      case BrandLogoVariant.white:
        // até haver export one-color branco do manual
        return BrandAssets.movlyLogoLimeOnPurple;
    }
  }

  /// Largura proporcional às dimensões nativas de cada PNG.
  static double _widthFor(BrandLogoVariant v, double h) {
    switch (v) {
      case BrandLogoVariant.purple:
        return h * (813 / 414);
      case BrandLogoVariant.lime:
      case BrandLogoVariant.white:
        return h * (791 / 386);
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = _assetFor(variant);
    final w = _widthFor(variant, height);

    return Semantics(
      label: 'movly by ACAF',
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
