import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gym_hero_sliver_app_bar.dart';
import '../widgets/gym_hero_visual.dart';
import '../widgets/gym_photo_gallery.dart';
import '../widgets/gym_unit_enrollment_content.dart';

class GymDetailScreen extends StatefulWidget {
  const GymDetailScreen({super.key, required this.gym, this.network});

  final Gym gym;
  final GymNetwork? network;

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;
    final network = widget.network;
    final hasHeroPhoto = GymHeroVisual.hasCoverPhoto(gym);
    final collapsedTitle = network?.name ?? gym.name;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: gymUnitStickyActions(context, gym),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          GymHeroSliverAppBar(
            scrollController: _scrollController,
            title: collapsedTitle,
            hasHeroPhoto: hasHeroPhoto,
            expandedSubtitle: gym.unitLabel,
            heroBackground: GymPhotoGallery(
              gym: gym,
              network: network,
              height: GymHeroSliverAppBar.expandedHeightWithPhoto,
              logoHeight: 64,
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
