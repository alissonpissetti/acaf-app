import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_session_store.dart';

enum BiometricAvailability {
  available,
  notEnrolled,
  notSupported,
  unknown,
}

class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    BiometricSessionStore? sessionStore,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _sessionStore = sessionStore ?? BiometricSessionStore();

  final LocalAuthentication _localAuth;
  final BiometricSessionStore _sessionStore;

  BiometricSessionStore get sessionStore => _sessionStore;

  Future<BiometricAvailability> checkAvailability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return BiometricAvailability.notSupported;

      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      if (!canCheck && types.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }
      if (types.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }
      return BiometricAvailability.available;
    } catch (e, st) {
      debugPrint('BiometricAuth: disponibilidade: $e');
      debugPrint('$st');
      return BiometricAvailability.unknown;
    }
  }

  Future<String> localizedBiometricLabel() async {
    final types = await _localAuth.getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return defaultTargetPlatform == TargetPlatform.iOS ? 'Face ID' : 'Reconhecimento facial';
    }
    if (types.contains(BiometricType.fingerprint)) {
      return 'Impressão digital';
    }
    if (types.contains(BiometricType.iris)) {
      return 'Íris';
    }
    return 'Biometria';
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e, st) {
      debugPrint('BiometricAuth: falha na autenticação: ${e.code} ${e.message}');
      debugPrint('$st');
      return false;
    } catch (e, st) {
      debugPrint('BiometricAuth: erro: $e');
      debugPrint('$st');
      return false;
    }
  }

  Future<bool> shouldShowUnlockGate({required bool hasLocalSession}) async {
    if (!hasLocalSession) return false;
    final enabled = await _sessionStore.isBiometricUnlockEnabled();
    if (!enabled) return false;
    return _sessionStore.hasBoundSession();
  }

  Future<bool> enableBiometricUnlock() async {
    final availability = await checkAvailability();
    if (availability != BiometricAvailability.available) {
      return false;
    }

    final label = await localizedBiometricLabel();
    final ok = await authenticate(
      reason: 'Confirme com $label para proteger o acesso ao movly.',
    );
    if (!ok) return false;

    await _sessionStore.bindSessionForBiometricUnlock();
    await _sessionStore.setBiometricUnlockEnabled(true);
    return true;
  }

  Future<bool> disableBiometricUnlock() async {
    await _sessionStore.setBiometricUnlockEnabled(false);
    return true;
  }
}
