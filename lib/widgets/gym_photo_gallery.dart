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

  @override
  Widget build(BuildContext context) {
    final photos = widget.gym.photoAssets;
    if (photos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: GymHeroVisual(
          gym: widget.gym,
          network: widget.network,
          overlayLogoHeight: widget.logoHeight,
        ),
      );
    }

    if (photos.length == 1) {
      return SizedBox(
        height: widget.height,
        child: GymHeroVisual(
          gym: widget.gym,
          network: widget.network,
          overlayLogoHeight: widget.logoHeight,
          heroImageOverride: photos.first,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
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
