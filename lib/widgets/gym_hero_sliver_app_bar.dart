import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_logo.dart';
import 'gym_collapsed_app_bar_title.dart';

/// App bar do detalhe da unidade/rede: faixa roxa fixa no topo; hero (foto/degradê) abaixo;
/// nome grande só no hero expandido, some ao colapsar.
class GymHeroSliverAppBar extends StatelessWidget {
  const GymHeroSliverAppBar({
    super.key,
    required this.scrollController,
    required this.title,
    required this.hasHeroPhoto,
    required this.heroBackground,
    this.expandedSubtitle,
  });

  final ScrollController scrollController;
  final String title;
  final bool hasHeroPhoto;
  final Widget heroBackground;
  final String? expandedSubtitle;

  /// Altura visível do hero (foto ou degradê) abaixo da faixa roxa fixa.
  static const double heroContentHeightWithPhoto = 220;
  static const double heroContentHeightWithoutPhoto = 152;

  /// Opacidade da faixa roxa translúcida sobre o hero (manual Movly).
  static const double heroTopBarOpacity = 0.88;

  double _expandedHeight(BuildContext context) =>
      _toolbarTopInset(context) +
      heroVisualHeight(context, hasHeroPhoto);

  /// Altura do bloco foto/degradê abaixo da faixa roxa.
  static double heroVisualHeight(BuildContext context, bool hasHeroPhoto) {
    return hasHeroPhoto
        ? heroContentHeightWithPhoto
        : heroContentHeightWithoutPhoto;
  }

  double _toolbarTopInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + kToolbarHeight;

  double _collapseT(BuildContext context) {
    if (!scrollController.hasClients) return 0;
    final range = _expandedHeight(context) - _toolbarTopInset(context);
    if (range <= 1) return 1;
    return (scrollController.offset / range).clamp(0.0, 1.0);
  }

  bool _toolbarCollapsed(BuildContext context) => _collapseT(context) >= 0.98;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final collapsed = _toolbarCollapsed(context);
        final t = _collapseT(context);
        final toolbarTop = _toolbarTopInset(context);
        final showToolbarTitle = collapsed;
        final titleFade = (1.0 - t * 1.35).clamp(0.0, 1.0);
        final heroBottomLabel = expandedSubtitle ?? title;

        return SliverAppBar(
          expandedHeight: _expandedHeight(context),
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          title: showToolbarTitle
              ? GymCollapsedAppBarTitle(label: title, onHero: true)
              : const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BrandLogo(height: 28, variant: BrandLogoVariant.lime),
                ),
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(
                centerTitle: false,
                expandedTitleScale: 1,
                collapseMode: CollapseMode.pin,
                title: titleFade > 0.02
                    ? Opacity(
                        opacity: titleFade,
                        child: _HeroBottomTitle(text: heroBottomLabel),
                      )
                    : null,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  end: 16,
                  bottom: 14,
                ),
                background: Column(
                  children: [
                    SizedBox(height: toolbarTop),
                    Expanded(
                      child: ClipRect(child: heroBackground),
                    ),
                  ],
                ),
              ),
              if (!collapsed)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _GymHeroTopBar(opacity: heroTopBarOpacity),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: toolbarTop,
                child: IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.primary.withValues(alpha: t * 0.94),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GymHeroTopBar extends StatelessWidget {
  const _GymHeroTopBar({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final barHeight = top + kToolbarHeight;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
      ),
      child: SizedBox(height: barHeight),
    );
  }
}

class _HeroBottomTitle extends StatelessWidget {
  const _HeroBottomTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.cardTitle.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(color: Color(0xCC000000), blurRadius: 12),
          Shadow(color: Color(0x99000000), blurRadius: 4),
        ],
      ),
    );
  }
}
