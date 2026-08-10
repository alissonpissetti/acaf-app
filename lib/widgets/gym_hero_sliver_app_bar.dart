import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'gym_collapsed_app_bar_title.dart';

/// App bar do detalhe da unidade/rede: título só na barra ao rolar; sobre foto, nome na base do hero.
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

  static const double expandedHeightWithPhoto = 200;
  static const double expandedHeightWithoutPhoto = 140;

  double get _expandedHeight =>
      hasHeroPhoto ? expandedHeightWithPhoto : expandedHeightWithoutPhoto;

  bool _toolbarCollapsed(BuildContext context) {
    if (!scrollController.hasClients) return false;
    final top = MediaQuery.paddingOf(context).top;
    final threshold = _expandedHeight - kToolbarHeight - top - 6;
    return scrollController.offset >= threshold;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final collapsed = _toolbarCollapsed(context);
        final showToolbarTitle = !hasHeroPhoto || collapsed;
        final onPhotoToolbar = hasHeroPhoto && !collapsed;

        return SliverAppBar(
          expandedHeight: _expandedHeight,
          pinned: true,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.foreground,
          iconTheme: IconThemeData(
            color: onPhotoToolbar ? Colors.white : AppColors.foreground,
          ),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          title: showToolbarTitle
              ? GymCollapsedAppBarTitle(label: title)
              : const SizedBox.shrink(),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            expandedTitleScale: 1,
            collapseMode: CollapseMode.parallax,
            title: _flexibleTitle(showToolbarTitle),
            titlePadding: showToolbarTitle && hasHeroPhoto
                ? const EdgeInsetsDirectional.only(start: 48, bottom: 12)
                : const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 14),
            background: heroBackground,
          ),
        );
      },
    );
  }

  Widget? _flexibleTitle(bool showToolbarTitle) {
    if (hasHeroPhoto && !showToolbarTitle) {
      return _HeroBottomTitle(text: title);
    }
    if (!hasHeroPhoto && expandedSubtitle != null) {
      return Text(
        expandedSubtitle!,
        style: AppTypography.cardTitle.copyWith(color: AppColors.foreground),
      );
    }
    return null;
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
