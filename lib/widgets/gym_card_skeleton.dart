import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder enquanto carrega mais unidades na home.
class GymCardSkeleton extends StatelessWidget {
  const GymCardSkeleton({super.key});

  static const _heroAspectRatio = 16 / 10;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: const AspectRatio(
              aspectRatio: _heroAspectRatio,
              child: _Bone(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Bone(height: 18, width: 200),
                const SizedBox(height: 10),
                const _Bone(height: 14, width: 140),
                const SizedBox(height: 8),
                const _Bone(height: 14, width: 240),
                const SizedBox(height: 12),
                const _Bone(height: 40, borderRadius: BorderRadius.all(Radius.circular(12))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _Bone(height: 56, borderRadius: BorderRadius.circular(14))),
                    const SizedBox(width: 8),
                    Expanded(child: _Bone(height: 56, borderRadius: BorderRadius.circular(14))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: borderRadius,
      ),
    );
  }
}
