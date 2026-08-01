import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gym.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/daily_pass_qr_view.dart';
import 'daily_pass_qr_screen.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({
    super.key,
    required this.gym,
    required this.type,
    this.planName,
  });

  final Gym gym;
  final PurchaseType type;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDaily = type == PurchaseType.dailyPass;
    final dailyItem = isDaily ? appState.activeDailyPassForGym(gym.id) : null;
    final code = dailyItem?.checkInCode;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Tudo certo!')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.orangeSoft,
              child: const Icon(Icons.check_rounded, size: 48, color: AppColors.orange),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isDaily ? 'Diária confirmada' : 'Assinatura ativa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isDaily
                ? 'Use o QR abaixo para check-in em ${gym.name}. Você pode reabri-lo a qualquer momento hoje.'
                : 'Plano $planName em ${gym.name}.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 32),
          if (isDaily && code != null && dailyItem != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    DailyPassQrView(payload: code, size: 180),
                    const SizedBox(height: 12),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Válido até o fim do dia · mesmo QR ao reabrir',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          if (isDaily && dailyItem != null) ...[
            OutlinedButton.icon(
              onPressed: () => DailyPassQrScreen.open(context, dailyItem.id),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text('Abrir QR em tela cheia'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Voltar ao início'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<AppState>().openPlanTab();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Ver em Minha conta'),
          ),
        ],
      ),
    );
  }
}
