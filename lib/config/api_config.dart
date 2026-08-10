import 'dart:io';

import 'package:flutter/foundation.dart';

/// URL base da acaf-api (sem `/api`).
class ApiConfig {
  static const int defaultPort = 8787;

  /// Override em testes: `ApiConfig.overrideBaseUrl = 'http://...'`
  static String? overrideBaseUrl;

  static String resolveBaseUrl() {
    final override = overrideBaseUrl?.trim();
    if (override != null && override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/+$'), '');
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
