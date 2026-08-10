import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'member_check_in_screen.dart';

/// Check-in automático para diária ativa (geolocalização).
class DailyPassQrScreen extends StatelessWidget {
  const DailyPassQrScreen({super.key, required this.walletItemId});

  final String walletItemId;

  static void open(BuildContext context, String walletItemId) {
    final item = context.read<AppState>().walletItemById(walletItemId);
    if (item == null || item.checkInCode == null || !item.isActiveDailyPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diária não encontrada ou expirada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberCheckInScreen(
          gym: item.gym,
          planName: item.title,
          checkInCode: item.checkInCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  // Mantido para compatibilidade de rotas; o fluxo real abre MemberCheckInScreen.
    return const SizedBox.shrink();
  }
}
