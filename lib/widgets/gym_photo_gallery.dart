import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';
import 'gym_hero_visual.dart';

/// Carrossel de fotos no detalhe da unidade.
class GymPhotoGallery extends StatefulWidget {
  const GymPhotoGallery({
    super.key,
    required this.gym,
    this.network,
    this.height = 200,
    this.logoHeight = 64,
  });

  final Gym gym;
  final GymNetwork? network;
  final double height;
  final double logoHeight;

  @override
  State<GymPhotoGallery> createState() => _GymPhotoGalleryState();
}

class _GymPhotoGalleryState extends State<GymPhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _sizedHero(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : widget.height;
        return SizedBox(width: double.infinity, height: h, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.gym.photoAssets;
    final heroLogoAlignment = GymHeroLogoAlignment.bottomRight;

    if (photos.isEmpty) {
      return _sizedHero(
        GymHeroVisual(
          gym: widget.gym,
          network: widget.network,
          overlayLogoHeight: widget.logoHeight,
          logoAlignment: heroLogoAlignment,
          photoScrim: PhotoScrim.subtle,
        ),
      );
    }

    if (photos.length == 1) {
      return _sizedHero(
        GymHeroVisual(
          gym: widget.gym,
          network: widget.network,
          overlayLogoHeight: widget.logoHeight,
          heroImageOverride: photos.first,
          logoAlignment: heroLogoAlignment,
          photoScrim: PhotoScrim.subtle,
        ),
      );
    }

    return _sizedHero(
      Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return GymHeroVisual(
                gym: widget.gym,
                network: widget.network,
                overlayLogoHeight: widget.logoHeight,
                heroImageOverride: photos[index],
                showBrandLogo: index == 0,
                logoAlignment: heroLogoAlignment,
                photoScrim: PhotoScrim.subtle,
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => Container(
                  width: i == _index ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.orange : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
