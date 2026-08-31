import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/unit_subscription_plans.dart';
import '../models/gym.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'purchase_success_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, required this.gym});

  final Gym gym;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionPlan? _selected;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final connectSub = appState.activeConnectSubscription;
    final connectPlan = connectPlanForSubscription(connectSub);
    final allPlans = sortedUnitPlans(widget.gym.plans);
    final subscribable = eligibleUnitPlansForConnect(widget.gym.plans, connectSub?.planId);
    final selected = _effectiveSelected(subscribable, connectSub?.planId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Plano na unidade')),
      body: connectSub == null
          ? _NoEligibleBody(hasConnect: false, connectPlanName: null)
          : allPlans.isEmpty
              ? const _NoEligibleBody(
                  hasConnect: true,
                  connectPlanName: null,
                  emptyUnit: true,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.gym.name, style: AppTypography.sectionTitle.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                      connectPlan != null
                          ? 'Todos os tiers desta unidade. Assine até o ${connectPlan.name}; '
                              'planos acima exigem upgrade em Minha conta.'
                          : 'Planos configurados nesta unidade.',
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: 24),
                    ...allPlans.map((plan) {
                      final userPlanId = connectSub.planId;
                      final isUserTier = plan.connectPlanId == userPlanId;
                      final isUpgrade = isUnitPlanAboveUserConnectTier(plan, userPlanId);
                      final canSubscribe = isUnitPlanSubscribable(plan, userPlanId);
                      final isSelected =
                          canSubscribe && selected != null && plan.id == selected.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          color: isUserTier
                              ? AppColors.orangeSoft.withValues(alpha: 0.55)
                              : isUpgrade
                                  ? AppColors.surfaceMuted
                                  : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.orange
                                  : isUpgrade
                                      ? AppColors.borderStrong
                                      : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (canSubscribe) {
                                setState(() => _selected = plan);
                              } else if (isUpgrade) {
                                _promptConnectUpgrade(context, plan.name);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          plan.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isUserTier)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Seu plano',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.orangeDark,
                                            ),
                                          ),
                                        )
                                      else if (isUpgrade)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Upgrade',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.foregroundSecondary,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}/mês',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isUpgrade ? AppColors.textMuted : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(plan.description),
                                  const SizedBox(height: 6),
                                  Text(
                                    plan.modalitiesLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isUpgrade
                                          ? AppColors.foregroundSecondary
                                          : AppColors.orangeDark,
                                    ),
                                  ),
                                  if (isUpgrade) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Suba para este tier em Minha conta para poder assinar na unidade.',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.orangeDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (canSubscribe) ...[
                                    const SizedBox(height: 12),
                                    ...plan.benefits.map(
                                      (b) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 18,
                                              color: AppColors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(b)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
      bottomNavigationBar: subscribable.isEmpty || selected == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => _confirm(context, selected),
                  child: Text(
                    'Assinar ${selected.name} · R\$ ${selected.pricePerMonth.toStringAsFixed(2)}/mês',
                  ),
                ),
              ),
            ),
    );
  }

  SubscriptionPlan? _effectiveSelected(List<SubscriptionPlan> subscribable, String? userPlanId) {
    if (subscribable.isEmpty) return null;
    if (_selected != null && subscribable.any((p) => p.id == _selected!.id)) {
      return _selected;
    }
    if (userPlanId != null) {
      final userTier = subscribable.where((p) => p.connectPlanId == userPlanId).firstOrNull;
      if (userTier != null) return userTier;
    }
    return subscribable.first;
  }

  void _promptConnectUpgrade(BuildContext context, String planName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade de plano'),
        content: Text(
          'O $planName nesta unidade libera mais modalidades, '
          'mas você precisa subir o tier da sua assinatura Connect em Minha conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().openPlanTab();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Ir para Minha conta'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar assinatura na unidade'),
        content: Text(
          '${plan.name} em ${widget.gym.name}.\n\n'
          '${plan.modalitiesLabel}\n\n'
          'Total: R\$ ${plan.pricePerMonth.toStringAsFixed(2)}/mês (simulado).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<AppState>().addSubscription(
          gym: widget.gym,
          plan: plan,
        );

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseSuccessScreen(
          gym: widget.gym,
          type: PurchaseType.subscription,
          planName: plan.name,
        ),
      ),
      (route) => route.isFirst,
    );
  }
}

class _NoEligibleBody extends StatelessWidget {
  const _NoEligibleBody({
    required this.hasConnect,
    this.connectPlanName,
    this.emptyUnit = false,
  });

  final bool hasConnect;
  final String? connectPlanName;
  final bool emptyUnit;

  @override
  Widget build(BuildContext context) {
    final message = !hasConnect
        ? 'Ative um plano app em Minha conta para assinar nesta unidade.'
        : emptyUnit
            ? 'Esta unidade ainda não publicou planos mensais.'
            : 'Não há planos nesta unidade compatíveis com ${connectPlanName ?? 'seu plano'}.';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (!hasConnect) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.read<AppState>().openPlanTab();
                Navigator.of(context).pop();
              },
              child: const Text('Ir para Minha conta'),
            ),
          ],
        ],
      ),
    );
  }
}
