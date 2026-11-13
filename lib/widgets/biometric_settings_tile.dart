import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/biometric_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BiometricSettingsTile extends StatefulWidget {
  const BiometricSettingsTile({super.key});

  @override
  State<BiometricSettingsTile> createState() => _BiometricSettingsTileState();
}

class _BiometricSettingsTileState extends State<BiometricSettingsTile> {
  bool _loading = true;
  bool _enabled = false;
  String _label = 'Biometria';
  BiometricAvailability _availability = BiometricAvailability.unknown;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<BiometricAuthService>();
    final enabled = await auth.sessionStore.isBiometricUnlockEnabled();
    final label = await auth.localizedBiometricLabel();
    final availability = await auth.checkAvailability();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _label = label;
      _availability = availability;
      _loading = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    final auth = context.read<BiometricAuthService>();
    setState(() => _loading = true);

    if (value) {
      final ok = await auth.enableBiometricUnlock();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              _availability != BiometricAvailability.available
                  ? 'Biometria indisponível neste dispositivo.'
                  : 'Não foi possível ativar $_label.',
            ),
          ),
        );
      }
    } else {
      await auth.disableBiometricUnlock();
    }

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = _availability != BiometricAvailability.available;

    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.orange),
        title: Text('Desbloqueio com $_label', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
        subtitle: Text(
          unavailable
              ? 'Configure biometria no dispositivo para usar esta opção.'
              : 'Na abertura do app, confirme sua identidade sem redigitar o código.',
          style: AppTypography.bodyMuted.copyWith(fontSize: 12),
        ),
        value: _enabled,
        onChanged: _loading || unavailable ? null : _onChanged,
      ),
    );
  }
}
