import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company_enrollment.dart';
import '../models/connect_product_plan.dart';
import '../models/gym.dart';
import '../models/primary_gym.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/account_empty_panel.dart';
import '../widgets/billing_statement_section.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/connect_page_header.dart';
import '../widgets/connect_primary_button.dart';
import '../widgets/saved_payment_cards_section.dart';
import 'connect_plan_checkout_screen.dart';
import 'daily_pass_qr_screen.dart';
import 'my_reservations_screen.dart';

class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UserAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ConnectPageHeader(
            title: 'Minha conta',
            subtitle: 'Carteira, cartões, extrato e plano aderido.',
            trailing: _AccountHeaderClose(),
          ),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                return ListView(
                  padding: ConnectBottomNav.listPadding(context, top: 8),
                  children: [
                    _ProfileSummary(enrollment: appState.companyEnrollment),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Plano aderido'),
                    const SizedBox(height: AppSpacing.item),
                    _SubscribedPlanSection(
                      connect: appState.activeConnectSubscription,
                      gymSub: appState.activeGymSubscription,
                      pendingPlanId: appState.hasConnectPlanPendingCheckout
                          ? appState.selectedConnectPlanId
                          : null,
                    ),
                    if (appState.primaryGym != null) ...[
                      const SizedBox(height: AppSpacing.section),
                      _SectionTitle('Academia principal'),
                      const SizedBox(height: AppSpacing.item),
                      _PrimaryGymSection(primary: appState.primaryGym!),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Carteira'),
                    const SizedBox(height: AppSpacing.item),
                    _WalletSection(items: appState.wallet),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Cartões cadastrados'),
                    const SizedBox(height: AppSpacing.item),
                    SavedPaymentCardsSection(cards: appState.savedCards),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Extrato financeiro'),
                    const SizedBox(height: AppSpacing.item),
                    BillingStatementSection(entries: appState.billingEntries),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Reservas de aula'),
                    const SizedBox(height: AppSpacing.item),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available_rounded, color: AppColors.orange),
                        title: const Text('Minhas reservas'),
                        subtitle: const Text('Horários reservados em modalidades com agenda'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => MyReservationsScreen.open(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeaderClose extends StatelessWidget {
  const _AccountHeaderClose();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.close_rounded, color: AppColors.foreground, size: 22),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.sectionTitle);
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.enrollment});

  final CompanyEnrollment? enrollment;

  @override
  Widget build(BuildContext context) {
    final label = enrollment?.collaboratorLabel ?? 'Colaborador';
    final company = enrollment?.companyName ?? 'Empresa não vinculada';
    final code = enrollment?.code;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.orangeSoft,
              child: Text(
                _initials(label),
                style: AppTypography.cardTitle.copyWith(color: AppColors.orangeDark, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                  Text(company, style: AppTypography.bodyMuted),
                  if (code != null) Text('Código $code', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }
}

class _PrimaryGymSection extends StatelessWidget {
  const _PrimaryGymSection({required this.primary});

  final PrimaryGymChoice primary;

  @override
  Widget build(BuildContext context) {
    final status = !primary.hasStartedCheckIns
        ? 'Aguardando o primeiro check-in nesta unidade.'
        : primary.canChangeToAnotherGym
            ? '${primary.checkInsSinceFirst} check-ins · você pode trocar de academia principal.'
            : '${primary.checkInsSinceFirst} check-ins · faltam ${primary.remainingCheckInsBeforeChange} '
                'para liberar a troca.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.home_work_rounded, color: AppColors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primary.gymName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(status, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribedPlanSection extends StatelessWidget {
  const _SubscribedPlanSection({
    required this.connect,
    required this.gymSub,
    this.pendingPlanId,
  });

  final ActiveConnectSubscription? connect;
  final ActiveGymSubscription? gymSub;
  final String? pendingPlanId;

  @override
  Widget build(BuildContext context) {
    if (connect == null && gymSub == null && pendingPlanId == null) {
      return AccountEmptyPanel(
        icon: Icons.workspace_premium_outlined,
        message: 'Nenhum plano ativo. Escolha um plano app em Minha conta.',
        actionLabel: 'Ir para Minha conta',
        onAction: () {
          context.read<AppState>().openPlanTab();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      );
    }

    return Column(
      children: [
        if (connect != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_rounded, color: AppColors.orange, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Connect', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Ativo', style: AppTypography.label.copyWith(color: AppColors.orangeDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(connect!.planName, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                  Text(
                    'R\$ ${connect!.pricePerMonth.toStringAsFixed(2)}/mês · desde ${_formatDate(connect!.since)}',
                    style: AppTypography.bodyMuted,
                  ),
                  Text(
                    'Cobrança no ${connect!.cardBrand} final ${connect!.cardLastFour}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.read<AppState>().openPlanTab();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('Alterar plano'),
                  ),
                ],
              ),
            ),
          ),
        if (pendingPlanId != null && connect == null) ...[
          Card(
            color: AppColors.surfaceMuted,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checkout pendente', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Plano selecionado aguardando cadastro do cartão.',
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: 10),
                  ConnectPrimaryButton(
                    label: 'Continuar checkout',
                    icon: Icons.credit_card_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConnectPlanCheckoutScreen(planId: pendingPlanId!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        if (gymSub != null) ...[
          if (connect != null) const SizedBox(height: AppSpacing.item),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano na unidade', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text(gymSub!.gymName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                  Text(
                    '${gymSub!.planName} · R\$ ${gymSub!.pricePerMonth.toStringAsFixed(2)}/mês',
                    style: AppTypography.bodyMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WalletSection extends StatelessWidget {
  const _WalletSection({required this.items});

  final List<WalletItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AccountEmptyPanel(
        icon: Icons.account_balance_wallet_outlined,
        message: 'Sua carteira lista assinaturas de unidade e diárias compradas no app.',
      );
    }

    return Column(
      children: items.map((item) {
        final isDaily = item.type == PurchaseType.dailyPass;
        final canOpenQr = isDaily && item.isActiveDailyPass && item.checkInCode != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.item),
          child: Card(
            child: ListTile(
              onTap: canOpenQr ? () => DailyPassQrScreen.open(context, item.id) : null,
              leading: Icon(
                isDaily ? Icons.qr_code_2_rounded : Icons.fitness_center_rounded,
                color: AppColors.orange,
              ),
              title: Text(item.title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
              subtitle: Text(
                '${item.gym.name}\n${_formatDate(item.purchasedAt)}'
                '${item.validUntil != null ? ' · válido até ${_formatDate(item.validUntil!)}' : ''}'
                '${canOpenQr ? '\nToque para abrir o QR de check-in' : ''}'
                '${!canOpenQr && item.checkInCode != null ? '\nCódigo ${item.checkInCode}' : ''}',
                style: AppTypography.bodyMuted.copyWith(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: canOpenQr
                  ? const Icon(Icons.chevron_right_rounded, color: AppColors.orange)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
