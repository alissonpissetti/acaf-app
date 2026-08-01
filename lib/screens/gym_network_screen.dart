import 'package:flutter/material.dart';

import '../data/gym_network_repository.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gym_collapsed_app_bar_title.dart';
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
  late List<Gym> _units;
  late Gym _selected;

  @override
  void initState() {
    super.initState();
    final repository = GymNetworkRepository();
    _units = repository.unitsForNetwork(widget.network.id);
    _selected = _resolveInitialUnit();
  }

  Gym _resolveInitialUnit() {
    final initial = widget.initialUnit;
    if (initial != null) {
      final match = _units.where((u) => u.id == initial.id);
      if (match.isNotEmpty) return match.first;
    }
    return _units.first;
  }

  void _selectUnit(Gym unit) {
    if (unit.id == _selected.id) return;
    setState(() => _selected = unit);
  }

  @override
  Widget build(BuildContext context) {
    final gym = _selected;
    final hasHeroPhoto = gym.heroImageAsset != null;
    final minDaily = _units.map((u) => u.dailyPassPrice).reduce((a, b) => a < b ? a : b);
    final minPlan = _units
        .expand((u) => u.plans.map((p) => p.pricePerMonth))
        .reduce((a, b) => a < b ? a : b);

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
            title: GymCollapsedAppBarTitle(label: widget.network.name),
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
              titlePadding: const EdgeInsetsDirectional.only(start: 48, bottom: 12, end: 12),
              background: GymPhotoGallery(
                key: ValueKey(gym.id),
                gym: gym,
                network: widget.network,
                height: 200,
                logoHeight: 64,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _NetworkSummaryStrip(
                  network: widget.network,
                  unitCount: _units.length,
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
                  units: _units,
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
