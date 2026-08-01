import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gym_collapsed_app_bar_title.dart';
import '../widgets/gym_photo_gallery.dart';
import '../widgets/gym_unit_enrollment_content.dart';

class GymDetailScreen extends StatelessWidget {
  const GymDetailScreen({super.key, required this.gym, this.network});

  final Gym gym;
  final GymNetwork? network;

  @override
  Widget build(BuildContext context) {
    final hasHeroPhoto = gym.heroImageAsset != null;
    final collapsedTitle = network?.name ?? gym.name;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: gymUnitStickyActions(context, gym),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasHeroPhoto ? 200 : 140,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.foreground,
            iconTheme: IconThemeData(
              color: hasHeroPhoto ? Colors.white : AppColors.foreground,
            ),
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            titleSpacing: 0,
            title: GymCollapsedAppBarTitle(label: collapsedTitle),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              expandedTitleScale: 1,
              title: hasHeroPhoto
                  ? null
                  : Text(
                      gym.unitLabel,
                      style: AppTypography.cardTitle.copyWith(
                        color: Colors.white,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
              titlePadding: const EdgeInsetsDirectional.only(start: 48, bottom: 12),
              background: GymPhotoGallery(
                gym: gym,
                network: network,
                height: 200,
                logoHeight: 64,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                gymUnitEnrollmentSections(context, gym, network),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
