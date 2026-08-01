import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connect_product_plan.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_logo.dart';
import '../widgets/connect_primary_button.dart';

class ConnectPlanCheckoutSuccessScreen extends StatelessWidget {
  const ConnectPlanCheckoutSuccessScreen({
    super.key,
    required this.plan,
    required this.cardBrand,
    required this.cardLastFour,
  });

  final ConnectProductPlan plan;
  final String cardBrand;
  final String cardLastFour;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Assinatura ativa'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 24),
              children: [
                const Center(child: BrandLogo(height: 36)),
                const SizedBox(height: AppSpacing.section),
                _SuccessHero(planName: plan.name),
                const SizedBox(height: AppSpacing.section),
                Text('Resumo da assinatura', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.item),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: AppColors.orangeSoft,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PlanTierBadge(plan: plan),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name, style: AppTypography.cardTitle.copyWith(fontSize: 17)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}/mês',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryRow(
                              icon: Icons.fitness_center_rounded,
                              text: 'Modalidades conforme configuração de cada unidade visitada',
                            ),
                            const SizedBox(height: 10),
                            const _SummaryRow(
                              icon: Icons.qr_code_scanner_rounded,
                              text: '1 check-in por dia em qualquer unidade da rede',
                            ),
                            const SizedBox(height: 10),
                            const _SummaryRow(
                              icon: Icons.autorenew_rounded,
                              text: 'Cobrança automática todo mês no cartão cadastrado',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.block),
                Text('Pagamento', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.item),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.credit_card_rounded, color: AppColors.orange, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cartão cadastrado', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('$cardBrand · final $cardLastFour', style: AppTypography.bodyMuted),
                              const SizedBox(height: 4),
                              Text(
                                'Débito recorrente autorizado',
                                style: AppTypography.caption.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.block),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Próximo passo', style: AppTypography.caption.copyWith(color: AppColors.foreground)),
                      const SizedBox(height: 6),
                      Text(
                        'Abra o Guia, escolha uma unidade e faça check-in. '
                        'Suas modalidades valem na academia visitada.',
                        style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ConnectStickyActions(
            children: [
              ConnectPrimaryButton(
                label: 'Ir para Minha conta',
                icon: Icons.wallet_rounded,
                onPressed: () => _goToPlan(context),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<AppState>().openGuideTab();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Explorar unidades no Guia'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPlan(BuildContext context) {
    context.read<AppState>().openPlanTab();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero({required this.planName});

  final String planName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orangeSoft,
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.check_rounded, size: 44, color: AppColors.orange),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Ativo',
                  style: AppTypography.label.copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Plano confirmado', style: AppTypography.pageTitle.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          planName,
          textAlign: TextAlign.center,
          style: AppTypography.cardTitle.copyWith(fontSize: 16, color: AppColors.orangeDark),
        ),
        const SizedBox(height: 6),
        Text(
          'Sua assinatura ACAF Connect está ativa. '
          'Você já pode usar a rede conforme o plano escolhido.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
      ],
    );
  }
}

class _PlanTierBadge extends StatelessWidget {
  const _PlanTierBadge({required this.plan});

  final ConnectProductPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 22, color: AppColors.orangeDark),
          const SizedBox(height: 6),
          Text(
            plan.tierShortName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.orangeDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTypography.bodyMuted.copyWith(fontSize: 13))),
      ],
    );
  }
}
