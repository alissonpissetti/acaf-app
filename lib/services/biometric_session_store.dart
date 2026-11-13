import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de biometria e token de sessão (nunca armazena senha ou código em texto).
class BiometricSessionStore {
  BiometricSessionStore({
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ?? const FlutterSecureStorage();

  static const _prefKeyEnabled = 'biometric_unlock_enabled_v1';
  static const _secureSessionTokenKey = 'biometric_session_token_v1';

  final FlutterSecureStorage _secure;

  Future<bool> isBiometricUnlockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? false;
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
    if (!enabled) {
      await _secure.delete(key: _secureSessionTokenKey);
    }
  }

  /// Vincula o desbloqueio biométrico à sessão atual (token opaco no Keychain/Keystore).
  Future<void> bindSessionForBiometricUnlock() async {
    final token = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 62)}';
    await _secure.write(key: _secureSessionTokenKey, value: token);
  }

  Future<bool> hasBoundSession() async {
    final token = await _secure.read(key: _secureSessionTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearBoundSession() async {
    await _secure.delete(key: _secureSessionTokenKey);
  }
}
