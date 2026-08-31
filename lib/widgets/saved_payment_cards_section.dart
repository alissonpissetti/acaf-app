import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_account.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'account_empty_panel.dart';

class SavedPaymentCardsSection extends StatelessWidget {
  const SavedPaymentCardsSection({super.key, required this.cards});

  final List<SavedPaymentCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return AccountEmptyPanel(
        icon: Icons.credit_card_outlined,
        message: 'Nenhum cartão cadastrado. O cartão é salvo ao concluir o checkout do plano.',
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
                              'Cartão da assinatura (não pode remover)',
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
                  content: Text('Cadastro de novo cartão disponível no checkout do plano.'),
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
