import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Modalidades permitidas na diária (configuração da unidade no painel academia).
class DailyPassModalitiesSection extends StatelessWidget {
  const DailyPassModalitiesSection({
    super.key,
    required this.gym,
    this.compact = false,
  });

  final Gym gym;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final included = gym.dailyPassIncludedModalities;
    final excluded = gym.dailyPassExcludedModalities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text('Modalidades incluídas na diária', style: AppTypography.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Configuradas e permitidas nesta unidade para visitantes com diária. '
            'Não inclui benefícios do plano ACAF Connect.',
            style: AppTypography.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.item),
        ] else
          Text('Incluídas na diária', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        if (included.isEmpty)
          Text(
            'A unidade ainda não publicou modalidades para diária.',
            style: AppTypography.bodyMuted.copyWith(fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: included.map((m) => _ModalityChip(label: m, included: true)).toList(),
          ),
        if (excluded.isNotEmpty && !compact) ...[
          const SizedBox(height: AppSpacing.item),
          Text(
            'Fora da diária nesta unidade: ${excluded.join(', ')}',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _ModalityChip extends StatelessWidget {
  const _ModalityChip({required this.label, required this.included});

  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: included ? AppColors.orangeSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: included ? AppColors.orange.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (included) ...[
            Icon(Icons.check_rounded, size: 14, color: AppColors.orangeDark),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: included ? AppColors.orangeDark : AppColors.foregroundSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
