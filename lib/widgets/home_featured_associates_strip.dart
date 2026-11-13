import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'gym_hero_visual.dart';

/// Faixa horizontal estilo "Top of Week" (cards com imagem, nome e preço).
class HomeFeaturedAssociatesStrip extends StatelessWidget {
  const HomeFeaturedAssociatesStrip({
    super.key,
    required this.gyms,
    required this.onGymTap,
    this.title = 'Destaques da semana',
  });

  final List<Gym> gyms;
  final ValueChanged<Gym> onGymTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (gyms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.item),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gyms.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _FeaturedAssociateTile(
                gym: gyms[index],
                onTap: () => onGymTap(gyms[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedAssociateTile extends StatelessWidget {
  const _FeaturedAssociateTile({required this.gym, required this.onTap});

  final Gym gym;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 100,
                  width: 132,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GymHeroVisual(
                        gym: gym,
                        showBrandLogo: false,
                        overlayLogoHeight: 28,
                      ),
                      if (gym.hasRating)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: AppColors.foreground),
                                const SizedBox(width: 2),
                                Text(
                                  gym.rating.toStringAsFixed(1),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.foreground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gym.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(fontSize: 13, height: 1.2),
              ),
              if (gym.offersPurchasableDailyPass) ...[
                const SizedBox(height: 2),
                Text(
                  'Diária R\$ ${gym.dailyPassPrice.toStringAsFixed(2)}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
