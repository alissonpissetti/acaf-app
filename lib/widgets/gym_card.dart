import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/modality_booking_access.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../screens/daily_pass_screen.dart';
import '../screens/subscription_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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

  static const _heroAspectRatio = 16 / 10;

  @override
  Widget build(BuildContext context) {
    final planFrom = gym.plans.map((p) => p.pricePerMonth).reduce((a, b) => a < b ? a : b);
    final logoAsset = network.logoSource ?? gym.brandLogoUrl ?? gym.brandLogoAsset;
    final hasGallery = gym.photoSources.length > 1;
    final visibleModalities = gym.modalities.take(3).toList();

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: _heroAspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GymHeroVisual(
                          gym: gym,
                          network: network,
                          overlayLogoHeight: logoAsset != null ? 44 : 40,
                          showFallbackIcon: logoAsset == null,
                          logoAlignment: GymHeroLogoAlignment.bottomRight,
                          photoScrim: GymHeroVisual.hasCoverPhoto(gym)
                              ? PhotoScrim.subtle
                              : PhotoScrim.full,
                        ),
                        if (distanceRank != null)
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _DistanceBadge(
                              rank: distanceRank!,
                              distanceKm: gym.distanceKm,
                            ),
                          ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: const _FavoriteStubButton(),
                        ),
                        if (hasGallery) const _GalleryCarouselHint(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.name,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purple,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (networkUnitCount != null && networkUnitCount! > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Unidade ${gym.unitLabel}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.foregroundSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _VenueMetaRow(gym: gym),
                        const SizedBox(height: 6),
                        _VenueLocationRow(gym: gym),
                        if (gym.modalities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ModalitiesSummaryLine(modalities: gym.modalities),
                        ],
                        if (visibleModalities.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _ModalityStatusChips(gym: gym, modalities: visibleModalities),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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

class _FavoriteStubButton extends StatelessWidget {
  const _FavoriteStubButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        tooltip: 'Favoritar',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favoritos em breve.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.favorite_border_rounded, color: AppColors.foreground),
      ),
    );
  }
}

class _GalleryCarouselHint extends StatelessWidget {
  const _GalleryCarouselHint();

  @override
  Widget build(BuildContext context) {
    Widget hint(IconData icon) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.92)),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(left: 6, top: 0, bottom: 0, child: Center(child: hint(Icons.chevron_left_rounded))),
          Positioned(right: 6, top: 0, bottom: 0, child: Center(child: hint(Icons.chevron_right_rounded))),
        ],
      ),
    );
  }
}

class _VenueMetaRow extends StatelessWidget {
  const _VenueMetaRow({required this.gym});

  final Gym gym;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        if (gym.hasRating) _StarRating(rating: gym.rating),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              '${gym.distanceKm.toStringAsFixed(1)} km',
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final filled = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final filledIcon = starValue <= filled.floor();
          final half = !filledIcon && starValue - 0.5 <= filled;
          return Icon(
            filledIcon
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: 16,
            color: AppColors.movlyPurple,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.caption.copyWith(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VenueLocationRow extends StatelessWidget {
  const _VenueLocationRow({required this.gym});

  final Gym gym;

  String get _secondaryLine {
    if (gym.name.contains('·')) {
      final tail = gym.name.split('·').last.trim();
      if (tail.isNotEmpty && tail.toLowerCase() != gym.neighborhood.toLowerCase()) {
        return tail;
      }
    }
    return gym.city;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.bodyMuted.copyWith(height: 1.4),
        children: [
          TextSpan(
            text: gym.neighborhood,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const TextSpan(text: ' · '),
          TextSpan(text: _secondaryLine),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ModalitiesSummaryLine extends StatelessWidget {
  const _ModalitiesSummaryLine({required this.modalities});

  final List<String> modalities;

  @override
  Widget build(BuildContext context) {
    final summary = modalities.length <= 4
        ? modalities.join(', ')
        : '${modalities.take(4).join(', ')} +${modalities.length - 4}';
    return Text.rich(
      TextSpan(
        style: AppTypography.bodyMuted.copyWith(height: 1.35),
        children: [
          TextSpan(
            text: 'Aulas: ',
            style: AppTypography.bodyMuted.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          TextSpan(text: summary),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ModalityStatusChips extends StatelessWidget {
  const _ModalityStatusChips({
    required this.gym,
    required this.modalities,
  });

  final Gym gym;
  final List<String> modalities;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Column(
      children: [
        for (var i = 0; i < modalities.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _ModalityPlanChip(
            modality: modalities[i],
            includedInPlan: _modalityIncludedInUserPlan(appState, gym, modalities[i]),
          ),
        ],
      ],
    );
  }

  bool _modalityIncludedInUserPlan(AppState appState, Gym gym, String modality) {
    final access = evaluateModalityBookingAccess(
      appState: appState,
      gym: gym,
      modality: modality,
    );
    return access.kind == ModalityBookingAccessKind.planMembership ||
        access.kind == ModalityBookingAccessKind.dailyPass;
  }
}

class _ModalityPlanChip extends StatelessWidget {
  const _ModalityPlanChip({
    required this.modality,
    required this.includedInPlan,
  });

  final String modality;
  final bool includedInPlan;

  @override
  Widget build(BuildContext context) {
    final bg = includedInPlan ? AppColors.limeSoft : AppColors.purpleSoft;
    final border = includedInPlan
        ? AppColors.lime.withValues(alpha: 0.45)
        : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              modality,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ),
          if (includedInPlan)
            const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({
    required this.rank,
    required this.distanceKm,
  });

  final int rank;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final label = rank == 1 ? 'Mais perto' : '#$rank';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 10,
              color: rank == 1 ? AppColors.purple : AppColors.textMuted,
            ),
          ),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: AppTypography.caption.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
                unitCount > 1 ? 'Ver rede · $unitCount unidades' : 'Ver rede',
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
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16, color: AppColors.purple),
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
              color: AppColors.purple,
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
      color: primary ? Colors.white : AppColors.purple,
      height: 1.1,
    );

    return Material(
      color: primary ? AppColors.purple : AppColors.surface,
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
              color: primary ? AppColors.purple : AppColors.border,
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
                color: primary ? Colors.white.withValues(alpha: 0.9) : AppColors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
