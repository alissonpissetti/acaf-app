import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/connect_plans.dart';
import '../models/connect_product_plan.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'company_enrollment_onboarding.dart';
import 'connect_plan_checkout_screen.dart';
import 'daily_pass_qr_screen.dart';
import 'user_account_screen.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/movly_tab_header.dart';
import '../widgets/connect_primary_button.dart';

class MyPlanScreen extends StatelessWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final identified = context.watch<AppState>().isEmployeeIdentified;
    if (!identified) {
      return const CompanyEnrollmentOnboarding();
    }
    return const _MyPlanContent();
  }
}

class _MyPlanContent extends StatelessWidget {
  const _MyPlanContent();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeConnect = appState.activeConnectSubscription;
    final selectedId = appState.selectedConnectPlanId;
    final gymSub = appState.activeGymSubscription;
    final enrollment = appState.companyEnrollment;
    final dailyPasses = appState.activeDailyPasses;

    return Column(
      children: [
        const MovlyTabHeader(
          title: 'Minha conta',
          subtitle: 'Seu benefício, plano e pagamentos em um só lugar.',
        ),
        Expanded(
          child: ListView(
            padding: ConnectBottomNav.listPadding(context, top: 20),
            children: [
              if (enrollment != null)
                Card(
                  color: AppColors.orangeSoft,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.orange, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enrollment.companyName,
                                style: AppTypography.cardTitle.copyWith(fontSize: 14),
                              ),
                              Text(
                                'Colaborador vinculado · ${enrollment.code}',
                                style: AppTypography.bodyMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (enrollment != null) const SizedBox(height: AppSpacing.block),
              if (activeConnect != null) ...[
                _ActiveConnectPlanCard(subscription: activeConnect),
                const SizedBox(height: AppSpacing.block),
              ],
              const _ConnectPlanRulesBanner(),
              const SizedBox(height: AppSpacing.block),
              Text('Compare os planos', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Do plano básico (Start) ao completo (Total). O valor mensal corresponde ao tier da assinatura.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.item),
              _PlanComparisonStrip(
                selectedId: selectedId,
                onSelect: (id) => context.read<AppState>().selectConnectPlan(id),
              ),
              const SizedBox(height: AppSpacing.block),
              Text('Detalhes do plano', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.item),
              ...connectProductPlans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.item),
                  child: _ConnectPlanCard(
                    plan: plan,
                    selected: selectedId == plan.id,
                    onSelect: () => context.read<AppState>().selectConnectPlan(plan.id),
                  ),
                ),
              ),
              if (selectedId != null && activeConnect == null) ...[
                const SizedBox(height: 8),
                ConnectPrimaryButton(
                  label: 'Confirmar plano escolhido',
                  icon: Icons.check_rounded,
                  onPressed: () => _openCheckout(context, selectedId),
                ),
              ],
              if (gymSub != null) ...[
                const SizedBox(height: AppSpacing.section),
                Text('Plano na unidade', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.item),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gymSub.gymName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${gymSub.planName} · R\$ ${gymSub.pricePerMonth.toStringAsFixed(2)}/mês',
                          style: AppTypography.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (dailyPasses.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                Text('Diárias ativas', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.item),
                ...dailyPasses.map(
                  (item) => Card(
                    child: ListTile(
                      dense: true,
                      onTap: item.checkInCode != null
                          ? () => DailyPassQrScreen.open(context, item.id)
                          : null,
                      leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.orange, size: 22),
                      title: Text(item.gym.name, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      subtitle: Text(
                        item.checkInCode != null
                            ? 'Toque para abrir o QR · ${item.checkInCode}'
                            : 'Código indisponível',
                        style: AppTypography.bodyMuted,
                      ),
                      trailing: item.checkInCode != null
                          ? const Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 20)
                          : null,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.block),
              TextButton.icon(
                onPressed: () => UserAccountScreen.open(context),
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: const Text('Carteira e extrato'),
              ),
              const SizedBox(height: AppSpacing.section),
              TextButton(
                onPressed: () => context.read<AppState>().clearEnrollment(),
                child: Text(
                  'Trocar empresa',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openCheckout(BuildContext context, String planId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectPlanCheckoutScreen(planId: planId),
      ),
    );
  }
}

class _ActiveConnectPlanCard extends StatelessWidget {
  const _ActiveConnectPlanCard({required this.subscription});

  final ActiveConnectSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.orangeSoft,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plano app ativo',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subscription.planName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
            Text(
              'R\$ ${subscription.pricePerMonth.toStringAsFixed(2)}/mês · débito recorrente',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: 4),
            Text(
              '${subscription.cardBrand} · final ${subscription.cardLastFour}',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectPlanRulesBanner extends StatelessWidget {
  const _ConnectPlanRulesBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Regra em todos os planos', style: AppTypography.caption.copyWith(color: AppColors.foreground)),
          const SizedBox(height: 8),
          const _RuleRow(
            icon: Icons.qr_code_scanner_rounded,
            text: '1 check-in por dia (máximo) em qualquer unidade da rede',
          ),
          const SizedBox(height: 6),
          const _RuleRow(
            icon: Icons.fitness_center_rounded,
            text: 'Modalidades válidas conforme o plano configurado na unidade do check-in',
          ),
          const SizedBox(height: 6),
          const _RuleRow(
            icon: Icons.hub_rounded,
            text: 'Acesso aos associados em todo o Brasil',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTypography.bodyMuted.copyWith(fontSize: 13))),
      ],
    );
  }
}

class _PlanComparisonStrip extends StatelessWidget {
  const _PlanComparisonStrip({
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < connectProductPlans.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _ComparisonTile(
              plan: connectProductPlans[i],
              selected: selectedId == connectProductPlans[i].id,
              onTap: () => onSelect(connectProductPlans[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final ConnectProductPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orangeSoft : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 108,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                plan.tierShortName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.orangeDark : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/mês',
                style: AppTypography.label.copyWith(
                  color: selected ? AppColors.orangeDark : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              if (plan.highlight) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Popular', style: AppTypography.label.copyWith(color: AppColors.orangeDark, fontSize: 9)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectPlanCard extends StatelessWidget {
  const _ConnectPlanCard({
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  final ConnectProductPlan plan;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanTierBadge(plan: plan, emphasized: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(plan.name, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                            ),
                            if (plan.highlight)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeSoft,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  'Popular',
                                  style: AppTypography.label.copyWith(color: AppColors.orangeDark),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}/mês',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(plan.description, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: AppTypography.bodyMuted.copyWith(fontSize: 13))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: selected ? AppColors.orange : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selected ? 'Plano selecionado' : 'Selecionar este plano',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.orange : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTierBadge extends StatelessWidget {
  const _PlanTierBadge({required this.plan, required this.emphasized});

  final ConnectProductPlan plan;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.orange.withValues(alpha: 0.1) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized ? AppColors.orange.withValues(alpha: 0.45) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 22,
            color: emphasized ? AppColors.orangeDark : AppColors.textMuted,
          ),
          const SizedBox(height: 6),
          Text(
            plan.tierShortName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontSize: 10,
              height: 1.15,
              color: emphasized ? AppColors.orangeDark : AppColors.foregroundSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
