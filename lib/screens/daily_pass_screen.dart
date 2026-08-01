import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_primary_button.dart';
import '../widgets/daily_pass_modalities_section.dart';
import 'daily_pass_checkout_screen.dart';

/// Resumo da diária antes do checkout (PIX, cartão salvo ou Apple Pay).
class DailyPassScreen extends StatelessWidget {
  const DailyPassScreen({super.key, required this.gym});

  final Gym gym;

  static String _todayLabel() {
    const weekdays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}.';
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel = gym.dailyPassPrice.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Diária para check-in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 120),
        children: [
          _UnitHeader(gym: gym, dateLabel: _todayLabel()),
          const SizedBox(height: AppSpacing.section),
          _DailyPassHeroCard(gym: gym, priceLabel: priceLabel),
          const SizedBox(height: AppSpacing.section),
          DailyPassModalitiesSection(gym: gym),
          const SizedBox(height: AppSpacing.section),
          Text('Como funciona', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.item),
          const _HowItWorksSteps(),
          const SizedBox(height: AppSpacing.block),
          if (gym.openHours.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Horário hoje: ${gym.openHours}',
                    style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total hoje', style: AppTypography.caption),
                        Text(
                          'R\$ $priceLabel',
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: 22,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '1 check-in',
                    style: AppTypography.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConnectPrimaryButton(
                label: 'Continuar para pagamento',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DailyPassCheckoutScreen(gym: gym),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.gym, required this.dateLabel});

  final Gym gym;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: gym.heroTint.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(gym.heroIcon, color: gym.heroTint, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gym.name, style: AppTypography.cardTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(gym.locationLabel, style: AppTypography.bodyMuted),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today_rounded, size: 16, color: AppColors.orangeDark),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyPassHeroCard extends StatelessWidget {
  const _DailyPassHeroCard({required this.gym, required this.priceLabel});

  final Gym gym;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.orangeSoft,
                  gym.heroTint.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.foreground.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 36,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diária · check-in', style: AppTypography.label),
                      const SizedBox(height: 4),
                      Text(
                        'Acesso único hoje',
                        style: AppTypography.cardTitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gym.unitLabel,
                        style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ $priceLabel',
                      style: AppTypography.pageTitle.copyWith(fontSize: 32),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'pagamento único',
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                _PassDetailRow(
                  icon: Icons.nightlight_round,
                  text: 'Válida até 23:59 de hoje nesta unidade.',
                ),
                const SizedBox(height: 10),
                _PassDetailRow(
                  icon: Icons.receipt_long_rounded,
                  text: 'Apresente o QR code na recepção após confirmar o pagamento.',
                ),
                const SizedBox(height: 10),
                _PassDetailRow(
                  icon: Icons.fitness_center_rounded,
                  text: 'Modalidades: ${gym.dailyPassModalitiesSummary}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassDetailRow extends StatelessWidget {
  const _PassDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksSteps extends StatelessWidget {
  const _HowItWorksSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData('1', 'Pagamento', 'PIX, cartão salvo, novo cartão ou Apple Pay.'),
      _StepData('2', 'QR code', 'Libera na hora na sua carteira ACAF Connect.'),
      _StepData('3', 'Check-in', 'Mostre o código na recepção e treine hoje.'),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepTile(data: steps[i]),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 16,
                  color: AppColors.border,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepData {
  const _StepData(this.number, this.title, this.subtitle);

  final String number;
  final String title;
  final String subtitle;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.orangeSoft,
          child: Text(
            data.number,
            style: AppTypography.caption.copyWith(
              color: AppColors.orangeDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(data.subtitle, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
