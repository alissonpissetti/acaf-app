import 'package:flutter/material.dart';

import '../data/open_hours_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GymOpenHoursSection extends StatelessWidget {
  const GymOpenHoursSection({
    super.key,
    this.weeklySchedule,
    this.summary = '',
    this.compact = false,
  });

  final Map<String, dynamic>? weeklySchedule;
  final String summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = openHoursRows(weeklySchedule: weeklySchedule, summary: summary);
    if (rows.isEmpty) return const SizedBox.shrink();

    final titleStyle = compact ? AppTypography.label : AppTypography.sectionTitle;
    final rowStyle = compact ? AppTypography.bodyMuted : AppTypography.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horários de funcionamento', style: titleStyle),
        const SizedBox(height: AppSpacing.tight),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, size: compact ? 16 : 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(row.daysLabel, style: rowStyle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    row.rangeLabel,
                    style: rowStyle.copyWith(
                      color: row.rangeLabel == 'Fechado'
                          ? AppColors.textMuted
                          : AppColors.foreground,
                      fontWeight: row.rangeLabel == 'Fechado' ? FontWeight.w500 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
