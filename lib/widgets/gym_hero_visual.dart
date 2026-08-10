import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';

/// Hero do card/detalhe: foto da API/unidade ou fallback com cor da rede.
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

  String? get _logoSource => network?.logoSource ?? gym.brandLogoUrl ?? gym.brandLogoAsset;

  double get _logoWidthFactor => network?.brandLogoWidthFactor ?? gym.brandLogoWidthFactor;

  /// URL ou asset usado como capa (hero, depois primeira da galeria).
  static String? resolveCoverPhoto(Gym gym, {String? override}) {
    if (override != null && override.isNotEmpty) return override;
    final heroUrl = gym.heroImageUrl;
    if (heroUrl != null && heroUrl.isNotEmpty) return heroUrl;
    final heroAsset = gym.heroImageAsset;
    if (heroAsset != null && heroAsset.isNotEmpty) return heroAsset;
    if (gym.galleryImageUrls.isNotEmpty) return gym.galleryImageUrls.first;
    if (gym.galleryImageAssets.isNotEmpty) return gym.galleryImageAssets.first;
    return null;
  }

  static bool hasCoverPhoto(Gym gym, {String? override}) =>
      resolveCoverPhoto(gym, override: override) != null;

  @override
  Widget build(BuildContext context) {
    final imagePath = resolveCoverPhoto(gym, override: heroImageOverride);
    final hasPhoto = imagePath != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPhoto)
          _HeroImage(source: imagePath)
        else
          _TintHeroFallback(tint: gym.heroTint),
        if (hasPhoto)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.28, 0.72, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
        if (showBrandLogo && _logoSource != null)
          Positioned(
            right: 10,
            top: 10,
            child: _LogoBadge(
              source: _logoSource!,
              width: overlayLogoHeight * _logoWidthFactor,
              height: overlayLogoHeight,
              semanticLabel: 'Logo ${network?.name ?? gym.name}',
              elevated: !hasPhoto,
            ),
          )
        else if (showFallbackIcon && _logoSource == null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                gym.heroIcon,
                size: overlayLogoHeight,
                color: hasPhoto
                    ? Colors.white.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fundo colorido da rede quando não há foto de capa.
class _TintHeroFallback extends StatelessWidget {
  const _TintHeroFallback({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    final mid = Color.lerp(tint, Colors.black, 0.22)!;
    final deep = Color.lerp(tint, Colors.black, 0.48)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.white, 0.14)!,
            mid,
            deep,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.04),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(source, fit: BoxFit.cover, alignment: Alignment.center);
    }
    return Image.asset(source, fit: BoxFit.cover, alignment: Alignment.center);
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({
    required this.source,
    required this.width,
    required this.height,
    required this.semanticLabel,
    this.elevated = false,
  });

  final String source;
  final double width;
  final double height;
  final String semanticLabel;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final image = source.startsWith('http://') || source.startsWith('https://')
        ? Image.network(source, width: width, height: height, fit: BoxFit.contain)
        : Image.asset(
            source,
            width: width,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );

    if (!elevated) {
      return Semantics(label: semanticLabel, child: image);
    }

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: image,
      ),
    );
  }
}
