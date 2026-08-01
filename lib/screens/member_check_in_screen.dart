import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gym.dart';
import '../models/primary_gym.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Check-in na academia principal (mockup).
class MemberCheckInScreen extends StatefulWidget {
  const MemberCheckInScreen({
    super.key,
    required this.gym,
    this.planName,
  });

  final Gym gym;
  final String? planName;

  @override
  State<MemberCheckInScreen> createState() => _MemberCheckInScreenState();
}

class _MemberCheckInScreenState extends State<MemberCheckInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().recordPrimaryGymCheckIn(widget.gym.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = 'CHK-${widget.gym.id.toUpperCase()}-${DateTime.now().day}';
    final primary = context.watch<AppState>().primaryGym;
    final progress = primary != null && primary.gymId == widget.gym.id
        ? _progressHint(primary.checkInsSinceFirst, primary.canChangeToAnotherGym)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.gym.name, style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(widget.gym.locationLabel, style: AppTypography.bodyMuted),
            if (widget.planName != null) ...[
              const SizedBox(height: 8),
              Text('Plano: ${widget.planName}', style: AppTypography.caption),
            ],
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(progress, style: AppTypography.caption.copyWith(color: AppColors.orangeDark)),
            ],
            const SizedBox(height: AppSpacing.section),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 120, color: AppColors.orange.withValues(alpha: 0.9)),
                    const SizedBox(height: 16),
                    Text(code, style: AppTypography.cardTitle.copyWith(letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                      'Apresente na recepção para liberar a entrada.',
                      style: AppTypography.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  String _progressHint(int count, bool canChange) {
    if (canChange) {
      return 'Check-in $count na sua academia principal · você já pode trocar de unidade.';
    }
    final left = (PrimaryGymChoice.minCheckInsToChange - count).clamp(0, PrimaryGymChoice.minCheckInsToChange);
    return 'Check-in $count na academia principal · faltam $left para liberar troca de unidade.';
  }
}
