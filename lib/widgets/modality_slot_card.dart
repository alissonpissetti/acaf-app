import 'package:flutter/material.dart';

import '../models/modality_schedule.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ModalityDaySummary extends StatelessWidget {
  const ModalityDaySummary({super.key, required this.slots});

  final List<ModalityAvailabilitySlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    final booked = slots.fold<int>(0, (sum, slot) => sum + slot.booked);
    final available = slots.fold<int>(0, (sum, slot) => sum + slot.available);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTypography.bodyMuted.copyWith(fontSize: 14),
          children: [
            TextSpan(
              text: '${slots.length}',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: slots.length == 1 ? ' horário' : ' horários'),
            const TextSpan(text: ' · '),
            TextSpan(
              text: '$booked',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: booked == 1 ? ' reserva' : ' reservas'),
            const TextSpan(text: ' · '),
            TextSpan(
              text: '$available',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: available == 1 ? ' vaga livre' : ' vagas livres',
            ),
          ],
        ),
      ),
    );
  }
}

class ModalitySlotCard extends StatelessWidget {
  const ModalitySlotCard({
    super.key,
    required this.slot,
    required this.onReserve,
    this.busy = false,
  });

  final ModalityAvailabilitySlot slot;
  final VoidCallback? onReserve;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final canReserve = !slot.isFull && onReserve != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${slot.startTime}–${slot.endTime}',
                        style: AppTypography.cardTitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(slot.modality, style: AppTypography.bodyMuted),
                      const SizedBox(height: 2),
                      Text(slot.instructorLabel, style: AppTypography.caption),
                    ],
                  ),
                ),
                ModalityOccupancyDonut(
                  booked: slot.booked,
                  capacity: slot.capacity,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ocupação', style: AppTypography.label),
                      const SizedBox(height: 4),
                      Text(slot.occupancyLabel, style: AppTypography.caption),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reservas', style: AppTypography.label),
                      const SizedBox(height: 4),
                      Text(slot.reservationsSummary, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: slot.capacity > 0 ? slot.fillRatio.clamp(0, 1) : 0,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: slot.isFull ? AppColors.textMuted : AppColors.orange,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: canReserve && !busy ? onReserve : null,
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      slot.isFull
                          ? 'Esgotado'
                          : onReserve == null
                              ? 'Sem acesso'
                              : 'Reservar este horário',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModalityOccupancyDonut extends StatelessWidget {
  const ModalityOccupancyDonut({
    super.key,
    required this.booked,
    required this.capacity,
  });

  final int booked;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final ratio = capacity > 0 ? (booked / capacity).clamp(0.0, 1.0) : 0.0;
    final isFull = capacity > 0 && booked >= capacity;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 5,
            backgroundColor: AppColors.border,
            color: isFull ? AppColors.textMuted : AppColors.orange,
          ),
          Text(
            capacity > 0 ? '$booked' : '—',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
