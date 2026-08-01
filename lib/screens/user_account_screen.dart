import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_enrollment_codes.dart';
import '../models/connect_product_plan.dart';
import '../models/gym.dart';
import '../models/primary_gym.dart';
import '../models/user_account.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/connect_page_header.dart';
import '../widgets/connect_primary_button.dart';
import 'connect_plan_checkout_screen.dart';
import 'daily_pass_qr_screen.dart';

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
                    _SavedCardsSection(cards: appState.savedCards),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle('Extrato financeiro'),
                    const SizedBox(height: AppSpacing.item),
                    _BillingSection(entries: appState.billingEntries),
                    const SizedBox(height: AppSpacing.section),
                    const _DemoPersistenceSection(),
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

class _DemoPersistenceSection extends StatelessWidget {
  const _DemoPersistenceSection();

  @override
  Widget build(BuildContext context) {
    final persistenceOk = context.watch<AppState>().persistencePlatformAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Demonstração'),
        const SizedBox(height: 6),
        Text(
          persistenceOk
              ? 'Vínculo, plano, carteira, cartões e extrato ficam salvos neste aparelho entre aberturas do app (mockup).'
              : 'Persistência nativa indisponível nesta execução (comum após hot restart). '
                  'Os dados valem só nesta sessão — pare o app e rode flutter run de novo para gravar no dispositivo.',
          style: AppTypography.bodyMuted.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.item),
        OutlinedButton.icon(
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.restart_alt_rounded, size: 20),
          label: const Text('Resetar mockup e começar do zero'),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetar demonstração?'),
        content: const Text(
          'Isso apaga neste dispositivo: empresa vinculada, planos, carteira, cartões e extrato. '
          'Você voltará ao fluxo inicial como na primeira instalação.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resetar')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AppState>().resetDemoData();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mockup resetado. Dados locais removidos.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    final label = enrollment?.collaboratorLabel ?? 'Colaborador ACAF Connect';
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
      return _EmptyPanel(
        icon: Icons.workspace_premium_outlined,
        message: 'Nenhum plano ativo. Escolha um plano ACAF Connect em Minha conta.',
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
                        child: Text('ACAF Connect', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
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
      return const _EmptyPanel(
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

class _SavedCardsSection extends StatelessWidget {
  const _SavedCardsSection({required this.cards});

  final List<SavedPaymentCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _EmptyPanel(
        icon: Icons.credit_card_outlined,
        message: 'Nenhum cartão cadastrado. O cartão é salvo ao concluir o checkout do plano Connect.',
        actionLabel: 'Ver planos',
        onAction: () {
          context.read<AppState>().openPlanTab();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      );
    }

    final appState = context.watch<AppState>();
    final connect = appState.activeConnectSubscription;

    return Column(
      children: [
        ...cards.map((card) {
          final locked = connect != null &&
              card.lastFour == connect.cardLastFour &&
              card.brand == connect.cardBrand;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.item),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded, color: AppColors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(card.brand, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                              if (card.isDefault) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Principal',
                                  style: AppTypography.label.copyWith(color: AppColors.orangeDark),
                                ),
                              ],
                            ],
                          ),
                          Text(card.maskedNumber, style: AppTypography.bodyMuted),
                          Text(
                            '${card.holderName} · val. ${card.expiryLabel}',
                            style: AppTypography.caption,
                          ),
                          if (locked)
                            Text(
                              'Cartão da assinatura Connect (não pode remover)',
                              style: AppTypography.caption.copyWith(color: AppColors.orangeDark),
                            ),
                        ],
                      ),
                    ),
                    if (!card.isDefault)
                      IconButton(
                        tooltip: 'Definir como principal',
                        onPressed: () => appState.setDefaultPaymentCard(card.id),
                        icon: const Icon(Icons.star_outline_rounded, size: 22),
                      ),
                    if (!locked)
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: () => appState.removePaymentCard(card.id),
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 22),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cadastro de novo cartão disponível no checkout do plano (mockup).'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Adicionar cartão'),
          ),
        ),
      ],
    );
  }
}

class _BillingSection extends StatelessWidget {
  const _BillingSection({required this.entries});

  final List<BillingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.receipt_long_outlined,
        message: 'Nenhuma movimentação ainda. Compras e mensalidades aparecem aqui.',
      );
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
    final groups = _groupByDate(entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumo do extrato', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${entries.length} lançamento${entries.length == 1 ? '' : 's'} · mais recentes primeiro',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total debitado', style: AppTypography.caption),
                  Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: AppTypography.cardTitle.copyWith(fontSize: 17, color: AppColors.foreground),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.item),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Lançamento', style: AppTypography.label.copyWith(fontSize: 10)),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(
                        'Valor',
                        textAlign: TextAlign.end,
                        style: AppTypography.label.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var g = 0; g < groups.length; g++) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Text(
                    _statementDateHeader(groups[g].$2.first.occurredAt),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                for (var i = 0; i < groups[g].$2.length; i++) ...[
                  _BillingStatementRow(entry: groups[g].$2[i]),
                  if (i < groups[g].$2.length - 1 || g < groups.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 14),
                ],
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  static List<(String, List<BillingEntry>)> _groupByDate(List<BillingEntry> entries) {
    final order = <String>[];
    final map = <String, List<BillingEntry>>{};
    for (final entry in entries) {
      final key = _formatDate(entry.occurredAt);
      if (!map.containsKey(key)) order.add(key);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return order.map((key) => (key, map[key]!)).toList();
  }

  static String _statementDateHeader(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  static String _statusLabel(BillingEntryStatus status) {
    return switch (status) {
      BillingEntryStatus.paid => 'Pago',
      BillingEntryStatus.pending => 'Pendente',
      BillingEntryStatus.failed => 'Falhou',
    };
  }
}

class _BillingStatementRow extends StatelessWidget {
  const _BillingStatementRow({required this.entry});

  final BillingEntry entry;

  @override
  Widget build(BuildContext context) {
    final lines = _BillingStatementRow._linesFor(entry);
    final time =
        '${entry.occurredAt.hour.toString().padLeft(2, '0')}:${entry.occurredAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.orangeSoft,
            child: Icon(_iconFor(entry.kind), size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lines.title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [time, if (lines.subtitle != null) lines.subtitle].join(' · '),
                  style: AppTypography.caption,
                ),
                if (entry.cardLastFour != null) ...[
                  const SizedBox(height: 2),
                  Text('Cartão ···· ${entry.cardLastFour}', style: AppTypography.caption),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- R\$ ${entry.amount.toStringAsFixed(2)}',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                _StatusChip(
                  label: _BillingSection._statusLabel(entry.status),
                  status: entry.status,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(BillingEntryKind kind) {
    return switch (kind) {
      BillingEntryKind.dailyPass => Icons.qr_code_2_rounded,
      BillingEntryKind.gymSubscription => Icons.fitness_center_rounded,
      BillingEntryKind.connectSubscription => Icons.workspace_premium_rounded,
    };
  }

  static _StatementLines _linesFor(BillingEntry entry) {
    final parts = entry.description.split(' · ').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    switch (entry.kind) {
      case BillingEntryKind.dailyPass:
        final gym = parts.length > 1 ? parts[1] : (parts.isNotEmpty ? parts.first : 'Diária');
        return _StatementLines(title: 'Diária · $gym', subtitle: 'Check-in avulso');
      case BillingEntryKind.gymSubscription:
        return _StatementLines(
          title: parts.isNotEmpty ? parts.first : 'Assinatura na unidade',
          subtitle: 'Mensalidade da academia',
        );
      case BillingEntryKind.connectSubscription:
        return _StatementLines(
          title: parts.isNotEmpty ? parts.first : 'Assinatura ACAF Connect',
          subtitle: 'Plano mensal Connect',
        );
    }
  }
}

class _StatementLines {
  const _StatementLines({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final BillingEntryStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      BillingEntryStatus.paid => (AppColors.success.withValues(alpha: 0.12), AppColors.success),
      BillingEntryStatus.pending => (AppColors.orangeSoft, AppColors.orangeDark),
      BillingEntryStatus.failed => (AppColors.error.withValues(alpha: 0.12), AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(fontSize: 9, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
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
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 8),
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

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
