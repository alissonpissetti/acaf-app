import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder enquanto carrega mais unidades na home.
class GymCardSkeleton extends StatelessWidget {
  const GymCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: const _Bone(height: 168),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Bone(height: 18, width: 180),
                const SizedBox(height: 10),
                const _Bone(height: 14, width: 120),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _Bone(height: 44, borderRadius: BorderRadius.circular(14))),
                    const SizedBox(width: 8),
                    Expanded(child: _Bone(height: 44, borderRadius: BorderRadius.circular(14))),
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
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double height;
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
