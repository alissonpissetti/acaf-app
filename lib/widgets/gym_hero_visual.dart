import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';

/// Hero do card/detalhe: foto da unidade ou fallback cor + ícone.
class GymHeroVisual extends StatelessWidget {
  const GymHeroVisual({
    super.key,
    required this.gym,
    this.network,
    this.overlayLogoHeight = 44,
    this.showFallbackIcon = true,
    this.heroImageOverride,
    this.showBrandLogo = true,
  });

  final Gym gym;
  final GymNetwork? network;
  final double overlayLogoHeight;
  final bool showFallbackIcon;
  final String? heroImageOverride;
  final bool showBrandLogo;

  String? get _logoAsset => network?.brandLogoAsset ?? gym.brandLogoAsset;

  double get _logoWidthFactor => network?.brandLogoWidthFactor ?? gym.brandLogoWidthFactor;

  @override
  Widget build(BuildContext context) {
    final imagePath = heroImageOverride ?? gym.heroImageAsset;
    final hasPhoto = imagePath != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPhoto)
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          )
        else
          ColoredBox(color: gym.heroTint),
        if (hasPhoto)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        if (showBrandLogo && _logoAsset != null)
          Positioned(
            right: 10,
            top: 10,
            child: Image.asset(
              _logoAsset!,
              width: overlayLogoHeight * _logoWidthFactor,
              height: overlayLogoHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Logo ${network?.name ?? gym.name}',
            ),
          )
        else if (showFallbackIcon && _logoAsset == null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                gym.heroIcon,
                size: overlayLogoHeight,
                color: hasPhoto
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppColors.foreground.withValues(alpha: 0.28),
              ),
            ),
          ),
      ],
    );
  }
}
