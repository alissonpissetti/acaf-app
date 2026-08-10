import 'dart:io';

import 'package:flutter/foundation.dart';

/// URL base da acaf-api (sem `/api`).
class ApiConfig {
  static const int defaultPort = 8787;

  /// API de produção (Coolify).
  static const String productionBaseUrl =
      'http://ucskoskgsgcswk0sock84sg4.76.13.66.204.sslip.io';

  /// Override em build: `--dart-define=ACAF_API_URL=http://...`
  static const String _dartDefineBaseUrl = String.fromEnvironment('ACAF_API_URL');

  /// Override em testes: `ApiConfig.overrideBaseUrl = 'http://...'`
  static String? overrideBaseUrl;

  static String resolveBaseUrl() {
    final override = overrideBaseUrl?.trim();
    if (override != null && override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/+$'), '');
    }

    final fromDefine = _dartDefineBaseUrl.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine.replaceAll(RegExp(r'/+$'), '');
    }

    if (kReleaseMode) {
      return productionBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort';
    }

    if (Platform.isAndroid) {
      // Emulador Android → host da máquina local.
      return 'http://10.0.2.2:$defaultPort';
    }

    return 'http://127.0.0.1:$defaultPort';
  }

  static String apiPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${resolveBaseUrl()}/api$normalized';
  }

  static String absoluteUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '${resolveBaseUrl()}$path';
  }
}
