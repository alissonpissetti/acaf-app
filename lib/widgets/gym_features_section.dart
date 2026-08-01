import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GymModalitiesSection extends StatelessWidget {
  const GymModalitiesSection({
    super.key,
    required this.modalities,
    this.compact = false,
    this.maxVisible,
  });

  final List<String> modalities;
  final bool compact;
  final int? maxVisible;

  @override
  Widget build(BuildContext context) {
    if (modalities.isEmpty) return const SizedBox.shrink();

    final visible = maxVisible == null ? modalities : modalities.take(maxVisible!).toList();
    final hidden = maxVisible == null ? 0 : modalities.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modalidades', style: compact ? AppTypography.label : AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.tight),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...visible.map((m) => Chip(label: Text(m), visualDensity: VisualDensity.compact)),
            if (hidden > 0) Chip(label: Text('+$hidden'), visualDensity: VisualDensity.compact),
          ],
        ),
      ],
    );
  }
}

class GymFacilitiesSection extends StatelessWidget {
  const GymFacilitiesSection({
    super.key,
    required this.facilities,
    this.maxItems,
    this.compact = false,
  });

  final List<GymFacility> facilities;
  final int? maxItems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) return const SizedBox.shrink();

    final visible = maxItems == null ? facilities : facilities.take(maxItems!).toList();
    final hidden = maxItems == null ? 0 : facilities.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estrutura e vantagens',
          style: compact ? AppTypography.label : AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.tight),
        ...visible.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _FacilityRow(facility: f, dense: compact),
          ),
        ),
        if (hidden > 0)
          Text(
            '+ $hidden itens · ver detalhes',
            style: AppTypography.caption.copyWith(color: AppColors.orange),
          ),
      ],
    );
  }
}

class _FacilityRow extends StatelessWidget {
  const _FacilityRow({required this.facility, this.dense = false});

  final GymFacility facility;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(facility.icon, size: dense ? 16 : 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(facility.label, style: dense ? AppTypography.bodyMuted : AppTypography.body)),
      ],
    );
  }
}
