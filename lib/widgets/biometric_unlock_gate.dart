import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../branding/movly_brand.dart';
import '../services/biometric_auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_logo.dart';
import '../widgets/connect_primary_button.dart';
import '../screens/company_enrollment_onboarding.dart';

/// Exige biometria na abertura (e ao voltar do background) quando habilitado e há sessão local.
class BiometricUnlockGate extends StatefulWidget {
  const BiometricUnlockGate({
    super.key,
    required this.child,
    required this.biometricAuth,
  });

  final Widget child;
  final BiometricAuthService biometricAuth;

  @override
  State<BiometricUnlockGate> createState() => _BiometricUnlockGateState();
}

class _BiometricUnlockGateState extends State<BiometricUnlockGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _skippedThisSession = false;
  bool _checking = true;
  bool _gateActive = false;
  String _biometricLabel = 'Biometria';
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_gateActive && _unlocked) {
        setState(() => _unlocked = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_gateActive && !_skippedThisSession && !_unlocked) {
        _tryAuthenticate();
      }
    }
  }

  Future<void> _evaluateGate() async {
    final appState = context.read<AppState>();
    final hasSession = appState.hasEstablishedSession;

    final showGate = await widget.biometricAuth.shouldShowUnlockGate(hasLocalSession: hasSession);
    final label = await widget.biometricAuth.localizedBiometricLabel();

    if (!mounted) return;
    setState(() {
      _checking = false;
      _gateActive = showGate;
      _biometricLabel = label;
      _unlocked = !showGate || _skippedThisSession;
    });

    if (showGate && !_skippedThisSession) {
      await _tryAuthenticate();
    }
  }

  Future<void> _tryAuthenticate() async {
    if (_authenticating || _unlocked) return;
    setState(() => _authenticating = true);

    final ok = await widget.biometricAuth.authenticate(
      reason: 'Desbloqueie o ${MovlyBrand.materialAppTitle} com $_biometricLabel.',
    );

    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _unlocked = true;
    });
  }

  void _skipForThisSession() {
    setState(() {
      _skippedThisSession = true;
      _unlocked = true;
    });
  }

  Future<void> _openEnrollmentFallback() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(child: CompanyEnrollmentOnboarding()),
        ),
      ),
    );
    if (!mounted) return;
    final identified = context.read<AppState>().isEmployeeIdentified;
    if (identified) {
      setState(() => _unlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_gateActive && !_unlocked) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Center(child: BrandLogo(height: 44)),
                const SizedBox(height: AppSpacing.section),
                Icon(
                  Icons.fingerprint_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.block),
                Text(
                  'Desbloquear com $_biometricLabel',
                  textAlign: TextAlign.center,
                  style: AppTypography.pageTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  'Proteja seus dados de plano, carteira e check-in.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted,
                ),
                const Spacer(),
                ConnectPrimaryButton(
                  label: _authenticating ? 'Aguardando...' : 'Usar $_biometricLabel',
                  icon: Icons.lock_open_rounded,
                  onPressed: _authenticating ? () {} : _tryAuthenticate,
                ),
                const SizedBox(height: AppSpacing.item),
                TextButton(
                  onPressed: _authenticating ? null : _skipForThisSession,
                  child: const Text('Continuar sem biometria desta vez'),
                ),
                const SizedBox(height: AppSpacing.tight),
                TextButton(
                  onPressed: _authenticating ? null : _openEnrollmentFallback,
                  child: const Text('Entrar com código da empresa'),
                ),
                const SizedBox(height: AppSpacing.section),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
