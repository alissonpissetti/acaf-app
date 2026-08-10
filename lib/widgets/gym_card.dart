import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../screens/daily_pass_screen.dart';
import '../screens/subscription_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'gym_features_section.dart';
import 'gym_hero_visual.dart';

enum GymCardContext {
  /// Lista inicial: cada item é uma unidade (distância); abre a rede.
  homeUnitIndex,
  /// Dentro da rede: escolher unidade e contratar.
  networkUnitPicker,
}

class GymCard extends StatelessWidget {
  const GymCard({
    super.key,
    required this.gym,
    required this.network,
    required this.onTap,
    this.distanceRank,
    this.cardContext = GymCardContext.networkUnitPicker,
    this.networkUnitCount,
  });

  final Gym gym;
  final GymNetwork network;
  final VoidCallback onTap;
  final int? distanceRank;
  final GymCardContext cardContext;
  final int? networkUnitCount;

  @override
  Widget build(BuildContext context) {
    final planFrom = gym.plans.map((p) => p.pricePerMonth).reduce((a, b) => a < b ? a : b);

    final hasCoverPhoto = GymHeroVisual.hasCoverPhoto(gym);
    final logoAsset = network.logoSource ?? gym.brandLogoUrl ?? gym.brandLogoAsset;
    final showDistanceIndex = distanceRank != null;
    final logoHeight = gym.heroImageAsset == null && logoAsset != null ? 56.0 : 48.0;
    final logoReserve = logoAsset != null ? logoHeight * network.brandLogoWidthFactor + 28.0 : 0.0;
    final heroHeight = hasCoverPhoto
        ? 120.0
        : showDistanceIndex
            ? 118.0
            : 92.0;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GymHeroVisual(
                      gym: gym,
                      network: network,
                      overlayLogoHeight: logoHeight,
                      showFallbackIcon: logoAsset == null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (distanceRank != null)
                                _DistanceBadge(
                                  rank: distanceRank!,
                                  distanceKm: gym.distanceKm,
                                  onDarkHero: true,
                                ),
                              const Spacer(),
                            ],
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(right: logoReserve),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  network.name,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  maxLines: showDistanceIndex ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Unidade ${gym.unitLabel}',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (gym.hasRating) ...[
                          _Meta(icon: Icons.star_rounded, label: gym.rating.toStringAsFixed(1), accent: true),
                          const SizedBox(width: 12),
                        ],
                        _Meta(icon: Icons.place_outlined, label: '${gym.distanceKm.toStringAsFixed(1)} km'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(gym.locationLabel, style: AppTypography.bodyMuted),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    GymModalitiesSection(
                      modalities: gym.modalities,
                      compact: true,
                      maxVisible: 3,
                    ),
                    const SizedBox(height: 12),
                    GymFacilitiesSection(facilities: gym.facilities, maxItems: 2, compact: true),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: cardContext == GymCardContext.homeUnitIndex
                  ? _HomeOpenNetworkFooter(
                      planFrom: planFrom,
                      dailyPrice: gym.dailyPassPrice,
                      showDailyPass: gym.dailyPassActive,
                      unitCount: networkUnitCount ?? 1,
                      onOpenNetwork: onTap,
                    )
                  : gym.dailyPassActive
                      ? Row(
                          children: [
                            Expanded(
                              child: _PriceActionButton(
                                label: 'Diária',
                                value: 'R\$ ${gym.dailyPassPrice.toStringAsFixed(2)}',
                                primary: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => DailyPassScreen(gym: gym),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PriceActionButton(
                                label: 'Planos a partir de',
                                value: 'R\$ ${planFrom.toStringAsFixed(0)}',
                                primary: false,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => SubscriptionScreen(gym: gym),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : _PriceActionButton(
                          label: 'Planos a partir de',
                          value: 'R\$ ${planFrom.toStringAsFixed(0)}',
                          primary: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SubscriptionScreen(gym: gym),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({
    required this.rank,
    required this.distanceKm,
    this.onDarkHero = false,
  });

  final int rank;
  final double distanceKm;
  final bool onDarkHero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rank == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Mais perto', style: AppTypography.label.copyWith(color: AppColors.orange)),
          )
        else if (rank <= 5)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '#$rank mais próxima',
              style: AppTypography.label.copyWith(
                color: onDarkHero ? Colors.white.withValues(alpha: 0.72) : AppColors.textMuted,
              ),
            ),
          ),
        Text(
          '${distanceKm.toStringAsFixed(1)} km',
          style: AppTypography.caption.copyWith(
            color: onDarkHero ? Colors.white : AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: accent ? AppColors.orange : AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: accent ? AppColors.orange : null,
            fontWeight: accent ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _HomeOpenNetworkFooter extends StatelessWidget {
  const _HomeOpenNetworkFooter({
    required this.planFrom,
    required this.dailyPrice,
    required this.showDailyPass,
    required this.unitCount,
    required this.onOpenNetwork,
  });

  final double planFrom;
  final double dailyPrice;
  final bool showDailyPass;
  final int unitCount;
  final VoidCallback onOpenNetwork;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showDailyPass) ...[
              Expanded(
                child: _PricingHighlightTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Diária nesta unidade',
                  value: 'R\$ ${dailyPrice.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _PricingHighlightTile(
                icon: Icons.card_membership_rounded,
                label: 'Planos desde',
                value: 'R\$ ${planFrom.toStringAsFixed(0)}/mês',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onOpenNetwork,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                unitCount > 1
                    ? 'Ver rede · $unitCount unidades'
                    : 'Ver rede',
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingHighlightTile extends StatelessWidget {
  const _PricingHighlightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16, color: AppColors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceActionButton extends StatelessWidget {
  const _PriceActionButton({
    required this.label,
    required this.value,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.label.copyWith(
      fontSize: 10,
      height: 1.2,
      color: primary ? Colors.white.withValues(alpha: 0.92) : AppColors.textMuted,
      letterSpacing: 0.15,
    );
    final valueStyle = AppTypography.cardTitle.copyWith(
      fontSize: primary ? 16 : 15,
      fontWeight: FontWeight.w700,
      color: primary ? Colors.white : AppColors.orange,
      height: 1.1,
    );

    return Material(
      color: primary ? AppColors.orange : AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary ? AppColors.orange : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: labelStyle),
                    const SizedBox(height: 4),
                    Text(value, style: valueStyle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: primary ? Colors.white.withValues(alpha: 0.9) : AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
