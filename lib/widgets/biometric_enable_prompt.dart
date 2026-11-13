import 'package:flutter/material.dart';

import '../services/biometric_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Oferece ativar biometria após identificação ou checkout bem-sucedido.
class BiometricEnablePrompt {
  BiometricEnablePrompt._();

  static Future<void> offerIfAppropriate(
    BuildContext context, {
    required BiometricAuthService biometricAuth,
  }) async {
    final enabled = await biometricAuth.sessionStore.isBiometricUnlockEnabled();
    if (enabled) return;

    final availability = await biometricAuth.checkAvailability();
    if (availability != BiometricAvailability.available) return;
    if (!context.mounted) return;

    final label = await biometricAuth.localizedBiometricLabel();
    if (!context.mounted) return;

    final accept = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            8,
            AppSpacing.pageX,
            MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Acesso rápido e seguro', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.tight),
              Text(
                'Ative $label para desbloquear o app sem digitar o código da empresa toda vez.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.block),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text('Ativar $label'),
              ),
              const SizedBox(height: AppSpacing.tight),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Agora não'),
              ),
            ],
          ),
        );
      },
    );

    if (accept != true || !context.mounted) return;

    final ok = await biometricAuth.enableBiometricUnlock();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          ok
              ? '$label ativado. Na próxima abertura, desbloqueie com biometria.'
              : 'Não foi possível ativar a biometria. Tente em Minha conta.',
        ),
      ),
    );
  }
}
