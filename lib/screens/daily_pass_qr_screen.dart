import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gym.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/daily_pass_qr_view.dart';

/// QR de check-in para diária ativa — sempre o mesmo código persistido na carteira.
class DailyPassQrScreen extends StatelessWidget {
  const DailyPassQrScreen({super.key, required this.walletItemId});

  final String walletItemId;

  static void open(BuildContext context, String walletItemId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyPassQrScreen(walletItemId: walletItemId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<AppState>().walletItemById(walletItemId);

    if (item == null || item.checkInCode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in · diária')),
        body: const Center(child: Text('Diária não encontrada ou expirada.')),
      );
    }

    if (!item.isActiveDailyPass) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in · diária')),
        body: const Center(child: Text('Esta diária não está mais válida.')),
      );
    }

    return _DailyPassQrBody(item: item);
  }
}

class _DailyPassQrBody extends StatelessWidget {
  const _DailyPassQrBody({required this.item});

  final WalletItem item;

  @override
  Widget build(BuildContext context) {
    final code = item.checkInCode!;
    final validLabel = item.validUntil != null
        ? 'Válida até ${_formatDateTime(item.validUntil!)}'
        : 'Válida hoje nesta unidade';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Check-in · diária')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.gym.name, style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(item.gym.locationLabel, style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.section),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DailyPassQrView(payload: code, size: 200),
                    const SizedBox(height: 16),
                    Text(
                      code,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(validLabel, style: AppTypography.bodyMuted, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'O QR é sempre o mesmo enquanto a diária estiver ativa.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} · $h:$m';
  }
}
