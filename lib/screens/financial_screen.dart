import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connect_product_plan.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/billing_statement_section.dart';
import '../widgets/saved_payment_cards_section.dart';

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FinancialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Financeiro')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final connect = appState.activeConnectSubscription;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pageX),
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.orange),
              const SizedBox(height: 16),
              Text('Financeiro', style: AppTypography.pageTitle.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                'Faturas, histórico de pagamentos e forma de cobrança.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.section),
              if (connect != null) ...[
                _SectionTitle('Cobrança do plano'),
                const SizedBox(height: AppSpacing.item),
                _ConnectBillingCard(subscription: connect),
                const SizedBox(height: AppSpacing.section),
              ],
              const _SectionTitle('Forma de cobrança'),
              const SizedBox(height: AppSpacing.item),
              SavedPaymentCardsSection(cards: appState.savedCards),
              const SizedBox(height: AppSpacing.section),
              const _SectionTitle('Extrato'),
              const SizedBox(height: AppSpacing.item),
              BillingStatementSection(entries: appState.billingEntries),
              const SizedBox(height: AppSpacing.section),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.cardTitle.copyWith(fontSize: 15, color: AppColors.foregroundSecondary),
    );
  }
}

class _ConnectBillingCard extends StatelessWidget {
  const _ConnectBillingCard({required this.subscription});

  final ActiveConnectSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.planName, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${subscription.pricePerMonth.toStringAsFixed(2)}/mês · cobrança no cartão',
                    style: AppTypography.bodyMuted,
                  ),
                  Text(
                    '${subscription.cardBrand} ···· ${subscription.cardLastFour}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
