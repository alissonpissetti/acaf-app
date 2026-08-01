import 'package:flutter/material.dart';

import '../branding/brand_assets.dart';

/// Exibe **apenas** [BrandAssets.connectLockup] — sem texto nem ícone substituto.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 44,
  });

  final double height;

  /// Remove artefato/linha na base do PNG oficial.
  static const _bottomCrop = 2.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          child: Image.asset(
            BrandAssets.connectLockup,
            height: height + _bottomCrop,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            filterQuality: FilterQuality.high,
            semanticLabel: 'ACAF Connect',
            gaplessPlayback: true,
            isAntiAlias: true,
          ),
        ),
      ),
    );
  }
}
