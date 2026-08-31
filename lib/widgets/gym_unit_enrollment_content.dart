import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/unit_subscription_plans.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../models/primary_gym.dart';
import '../navigation/open_connect_plan_tab.dart';
import '../screens/daily_pass_screen.dart';
import '../screens/subscription_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'connect_primary_button.dart';
import 'gym_features_section.dart';
import 'gym_modality_booking_section.dart';
import 'gym_open_hours_section.dart';

/// Barra fixa inferior: diária + academia principal.
Widget gymUnitStickyActions(BuildContext context, Gym gym) {
  final appState = context.watch<AppState>();
  final connectSub = appState.activeConnectSubscription;
  final primary = appState.primaryGym;
  final isPrimary = primary?.gymId == gym.id;

  return ConnectStickyActions(
    children: [
      ConnectPrimaryButton(
        label: 'Comprar diária · R\$ ${gym.dailyPassPrice.toStringAsFixed(2)}',
        icon: Icons.qr_code_2_rounded,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DailyPassScreen(gym: gym)),
          );
        },
      ),
      if (connectSub != null) ...[
        const SizedBox(height: 10),
        if (isPrimary)
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.home_work_rounded, size: 20),
            label: const Text('Sua academia principal'),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _onChoosePrimaryGym(context, gym, appState),
            icon: const Icon(Icons.home_work_outlined, size: 20),
            label: const Text('Escolher como Principal'),
          ),
      ],
    ],
  );
}

void _onChoosePrimaryGym(BuildContext context, Gym gym, AppState appState) async {
  final block = appState.primaryGymChangeBlockReason(gymId: gym.id);
  if (block != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(block), behavior: SnackBarBehavior.floating),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Escolher como Principal'),
      content: Text(
        'Confirmar ${gym.name} como sua unidade de referência na plataforma?\n\n'
        'Após o primeiro check-in aqui, serão necessários pelo menos '
        '${PrimaryGymChoice.minCheckInsToChange} check-ins nesta unidade antes de trocar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final error = await appState.trySetPrimaryGym(gymId: gym.id, gymName: gym.name);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
    );
    return;
  }
}

/// Blocos abaixo do hero: local, modalidades, planos, etc.
List<Widget> gymUnitEnrollmentSections(
  BuildContext context,
  Gym gym,
  GymNetwork? network,
) {
  final appState = context.watch<AppState>();
  final connectSub = appState.activeConnectSubscription;
  final connectPlan = connectPlanForSubscription(connectSub);
  final allPlans = sortedUnitPlans(gym.plans);
  final subscribable = eligibleUnitPlansForConnect(gym.plans, connectSub?.planId);
  final cheapestSubscribable = subscribable.isEmpty ? null : unitPlansFromPrice(subscribable);

  return [
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GymEnrollmentInfoPill(icon: Icons.star_rounded, text: gym.rating.toStringAsFixed(1)),
              const SizedBox(width: 8),
              GymEnrollmentInfoPill(
                icon: Icons.directions_walk_rounded,
                text: '${gym.distanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(gym.locationLabel, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
          if (network != null) ...[
            const SizedBox(height: 4),
            Text(network.name, style: AppTypography.bodyMuted),
          ],
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.block),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GymOpenHoursSection(
              weeklySchedule: gym.weeklySchedule,
              summary: gym.openHours,
            ),
            if (gym.modalities.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              GymModalitiesSection(modalities: gym.modalities),
            ],
            if (gym.facilities.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              GymFacilitiesSection(facilities: gym.facilities),
            ],
          ],
        ),
      ),
    ),
    const SizedBox(height: AppSpacing.section),
    GymModalityBookingSection(gym: gym),
    Text('Como acessar', style: AppTypography.sectionTitle),
    const SizedBox(height: AppSpacing.item),
    if (connectSub == null)
      GymEnrollmentOptionCard(
        icon: Icons.workspace_premium_outlined,
        title: 'Assinatura mensal na unidade',
        subtitle: 'Ative um plano app em Minha conta para ver opções aqui.',
        onTap: () => openConnectPlanTab(context),
      )
    else
      GymEnrollmentOptionCard(
        icon: Icons.card_membership_rounded,
        title: 'Assinatura mensal',
        subtitle: subscribable.isEmpty
            ? 'Veja os planos abaixo · faça upgrade do plano para assinar tiers superiores.'
            : '${allPlans.length} plano${allPlans.length == 1 ? '' : 's'} na unidade · '
                'assine até seu ${connectPlan?.name ?? 'tier'} · '
                'desde R\$ ${cheapestSubscribable!.toStringAsFixed(2)}',
        onTap: subscribable.isEmpty
            ? () {}
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SubscriptionScreen(gym: gym)),
                );
              },
      ),
    const SizedBox(height: 12),
    if (gym.dailyPassActive)
      GymEnrollmentOptionCard(
        icon: Icons.qr_code_2_rounded,
        title: 'Diária com check-in',
        subtitle: 'Válida hoje · R\$ ${gym.dailyPassPrice.toStringAsFixed(2)}',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DailyPassScreen(gym: gym)),
          );
        },
      ),
    if (gym.dailyPassActive) const SizedBox(height: AppSpacing.section),
    if (connectSub != null && appState.primaryGym?.gymId == gym.id) ...[
      Card(
        color: AppColors.orangeSoft,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.home_work_rounded, color: AppColors.orange, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sua academia principal', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    Text(
                      _primaryGymProgressLabel(appState.primaryGym!),
                      style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.block),
    ],
    Text('Planos na unidade', style: AppTypography.sectionTitle),
    const SizedBox(height: 6),
    if (connectSub != null && connectPlan != null)
      Text(
        'Todos os tiers configurados nesta unidade. Você assina até o ${connectPlan.name}; '
        'planos acima mostram o que libera um upgrade no app.',
        style: AppTypography.bodyMuted.copyWith(fontSize: 13),
      ),
    const SizedBox(height: AppSpacing.item),
    if (connectSub == null)
      _UnitPlansEmptyState(
        message: 'Vincule e ative um plano app para listar os planos compatíveis desta unidade.',
        actionLabel: 'Ir para Minha conta',
        onAction: () => openConnectPlanTab(context),
      )
    else if (allPlans.isEmpty)
      const _UnitPlansEmptyState(
        message: 'Esta unidade ainda não publicou planos mensais.',
      )
    else
      ...allPlans.map(
        (plan) {
          final isUserTier = plan.connectPlanId == connectSub.planId;
          final isUpgrade = isUnitPlanAboveUserConnectTier(plan, connectSub.planId);
          final canSubscribe = isUnitPlanSubscribable(plan, connectSub.planId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isUserTier
                  ? AppColors.orangeSoft
                  : isUpgrade
                      ? AppColors.surfaceMuted
                      : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: isUpgrade
                    ? () {
                        openConnectPlanTab(context);
                      }
                    : canSubscribe
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SubscriptionScreen(gym: gym),
                              ),
                            );
                          }
                        : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUpgrade ? AppColors.borderStrong : AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  plan.name,
                                  style: AppTypography.cardTitle.copyWith(fontSize: 15),
                                ),
                                if (isUserTier)
                                  _UnitPlanBadge(
                                    label: 'Seu plano',
                                    foreground: AppColors.orangeDark,
                                    background: AppColors.orange.withValues(alpha: 0.15),
                                  )
                                else if (isUpgrade)
                                  _UnitPlanBadge(
                                    label: 'Upgrade de plano',
                                    foreground: AppColors.foregroundSecondary,
                                    background: AppColors.surface,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(plan.description, style: AppTypography.bodyMuted),
                            const SizedBox(height: 4),
                            Text(
                              plan.modalitiesLabel,
                              style: AppTypography.caption.copyWith(
                                color: isUpgrade ? AppColors.foregroundSecondary : AppColors.orangeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isUpgrade) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Toque para subir de plano e liberar este tier aqui.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.orangeDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 15,
                          color: isUpgrade ? AppColors.textMuted : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    const SizedBox(height: 80),
  ];
}

String _primaryGymProgressLabel(PrimaryGymChoice primary) {
  if (!primary.hasStartedCheckIns) {
    return 'Faça seu primeiro check-in aqui para iniciar a contagem de permanência.';
  }
  if (primary.canChangeToAnotherGym) {
    return '${primary.checkInsSinceFirst} check-ins registrados · você já pode trocar de unidade principal.';
  }
  final left = primary.remainingCheckInsBeforeChange;
  return '${primary.checkInsSinceFirst} check-ins · faltam $left para poder trocar de academia principal.';
}

class _UnitPlansEmptyState extends StatelessWidget {
  const _UnitPlansEmptyState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _UnitPlanBadge extends StatelessWidget {
  const _UnitPlanBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTypography.label.copyWith(color: foreground, fontSize: 10)),
    );
  }
}

class GymEnrollmentInfoPill extends StatelessWidget {
  const GymEnrollmentInfoPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.orange),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class GymEnrollmentOptionCard extends StatelessWidget {
  const GymEnrollmentOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 20, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
