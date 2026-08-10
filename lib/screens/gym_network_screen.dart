import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/gym_network_repository.dart';
import '../state/catalog_state.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gym_hero_sliver_app_bar.dart';
import '../widgets/gym_hero_visual.dart';
import '../widgets/gym_photo_gallery.dart';
import '../widgets/gym_unit_enrollment_content.dart';

/// Rede: uma tela com seletor de unidade + contratação (sem lista de cards).
class GymNetworkScreen extends StatefulWidget {
  const GymNetworkScreen({
    super.key,
    required this.network,
    this.initialUnit,
  });

  final GymNetwork network;
  final Gym? initialUnit;

  @override
  State<GymNetworkScreen> createState() => _GymNetworkScreenState();
}

class _GymNetworkScreenState extends State<GymNetworkScreen> {
  List<Gym>? _units;
  Gym? _selected;
  bool _initialized = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final repository = GymNetworkRepository(context.read<CatalogState>());
    _units = repository.unitsForNetwork(widget.network.id);
    _selected = _resolveInitialUnit(_units!);
  }

  Gym _resolveInitialUnit(List<Gym> units) {
    final initial = widget.initialUnit;
    if (initial != null) {
      final match = units.where((u) => u.id == initial.id);
      if (match.isNotEmpty) return match.first;
    }
    return units.first;
  }

  void _selectUnit(Gym unit) {
    if (_selected == null || unit.id == _selected!.id) return;
    setState(() => _selected = unit);
  }

  @override
  Widget build(BuildContext context) {
    if (_units == null || _selected == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final units = _units!;
    final gym = _selected!;
    final hasHeroPhoto = GymHeroVisual.hasCoverPhoto(gym);
    final minDaily = units.map((u) => u.dailyPassPrice).reduce((a, b) => a < b ? a : b);
    final minPlan = units
        .expand((u) => u.plans.map((p) => p.pricePerMonth))
        .reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: gymUnitStickyActions(context, gym),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          GymHeroSliverAppBar(
            scrollController: _scrollController,
            title: widget.network.name,
            hasHeroPhoto: hasHeroPhoto,
            expandedSubtitle: gym.unitLabel,
            heroBackground: GymPhotoGallery(
              key: ValueKey(gym.id),
              gym: gym,
              network: widget.network,
              height: GymHeroSliverAppBar.expandedHeightWithPhoto,
              logoHeight: 64,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _NetworkSummaryStrip(
                  network: widget.network,
                  unitCount: units.length,
                  minDaily: minDaily,
                  minPlan: minPlan,
                ),
                const SizedBox(height: AppSpacing.section),
                Text('Escolha a unidade', style: AppTypography.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  'Diária ou plano na unidade desejada · ordem por distância',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.item),
                _NetworkUnitPicker(
                  units: units,
                  selected: gym,
                  onSelected: _selectUnit,
                ),
                const SizedBox(height: AppSpacing.block),
                ...gymUnitEnrollmentSections(context, gym, widget.network),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkSummaryStrip extends StatelessWidget {
  const _NetworkSummaryStrip({
    required this.network,
    required this.unitCount,
    required this.minDaily,
    required this.minPlan,
  });

  final GymNetwork network;
  final int unitCount;
  final double minDaily;
  final double minPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (network.brandLogoAsset != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                network.brandLogoAsset!,
                height: 44,
                width: 44 * network.brandLogoWidthFactor,
                fit: BoxFit.contain,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(network.name, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                if (network.tagline != null) ...[
                  const SizedBox(height: 2),
                  Text(network.tagline!, style: AppTypography.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text(
                  '$unitCount unidade${unitCount == 1 ? '' : 's'} · a partir de R\$ ${minDaily.toStringAsFixed(2)} diária · R\$ ${minPlan.toStringAsFixed(0)}/mês',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkUnitPicker extends StatelessWidget {
  const _NetworkUnitPicker({
    required this.units,
    required this.selected,
    required this.onSelected,
  });

  final List<Gym> units;
  final Gym selected;
  final ValueChanged<Gym> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: units.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final unit = units[index];
          final isSelected = unit.id == selected.id;
          return Material(
            color: isSelected ? AppColors.orangeSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => onSelected(unit),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppColors.orange : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit.unitLabel,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.orange : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${unit.distanceKm.toStringAsFixed(1)} km',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
