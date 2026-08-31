import 'package:flutter/material.dart';

import '../models/user_account.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'account_empty_panel.dart';

class BillingStatementSection extends StatelessWidget {
  const BillingStatementSection({super.key, required this.entries});

  final List<BillingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const AccountEmptyPanel(
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
    final lines = _linesFor(entry);
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
                  label: BillingStatementSection._statusLabel(entry.status),
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
          title: parts.isNotEmpty ? parts.first : 'Mensalidade',
          subtitle: 'Cobrança mensal no cartão',
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

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
