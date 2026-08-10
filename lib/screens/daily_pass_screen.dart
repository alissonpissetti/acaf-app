import 'package:flutter/material.dart';

import '../models/daily_pass_offer.dart';
import '../models/gym.dart';
import '../services/acaf_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_primary_button.dart';
import 'daily_pass_checkout_screen.dart';

/// Escolha da oferta de diária (integral ou faixa promocional) antes do checkout.
class DailyPassScreen extends StatefulWidget {
  const DailyPassScreen({super.key, required this.gym});

  final Gym gym;

  @override
  State<DailyPassScreen> createState() => _DailyPassScreenState();
}

class _DailyPassScreenState extends State<DailyPassScreen> {
  List<DailyPassOffer> _offers = [];
  DailyPassOffer? _selected;
  bool _loading = true;

  Gym get gym => widget.gym;

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final fallback = [
      DailyPassOffer.integralFromGym(
        id: 'base',
        price: gym.dailyPassPrice,
        modalities: gym.dailyPassIncludedModalities,
      ),
    ];

    final response = await AcafApi().fetchDailyPassOffers(
      unitId: gym.id,
      date: _todayIso(),
    );

    if (!mounted) return;

    final offers = response?.offers.isNotEmpty == true ? response!.offers : fallback;
    setState(() {
      _offers = offers;
      _selected = offers.first;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Diária para check-in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 120),
        children: [
          _UnitHeader(gym: gym, dateLabel: _todayLabel()),
          const SizedBox(height: AppSpacing.section),
          Text('Escolha a oferta de hoje', style: AppTypography.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Integral ou faixa promocional com horário e modalidades específicas.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.item),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            )
          else
            ..._offers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OfferCard(
                  offer: offer,
                  selected: selected?.id == offer.id,
                  onTap: () => setState(() => _selected = offer),
                ),
              ),
            ),
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
      bottomNavigationBar: selected == null
          ? null
          : SafeArea(
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
                                'R\$ ${selected.price.toStringAsFixed(2)}',
                                style: AppTypography.pageTitle.copyWith(
                                  fontSize: 22,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          selected.windowLabel,
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
                            builder: (_) => DailyPassCheckoutScreen(
                              gym: gym,
                              offer: selected,
                            ),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final DailyPassOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orangeSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.orange : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.label, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      offer.windowLabel,
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.validityLabel,
                      style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Modalidades: ${offer.modalitiesSummary}',
                      style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'R\$ ${offer.price.toStringAsFixed(2)}',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.orangeDark,
                ),
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

class _HowItWorksSteps extends StatelessWidget {
  const _HowItWorksSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData('1', 'Escolha a oferta', 'Integral ou faixa com horário e modalidades.'),
      _StepData('2', 'Pagamento', 'PIX, cartão salvo, novo cartão ou Apple Pay.'),
      _StepData('3', 'QR code', 'Libera na hora na sua carteira ACAF Connect.'),
      _StepData('4', 'Check-in', 'Mostre o código na recepção dentro da janela válida.'),
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
