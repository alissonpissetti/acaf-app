import 'dart:convert';
import 'dart:io';

/// Configuração pública de unidade no portal academia (API mock acaf_gym).
///
/// Em debug, opcional:
/// `GymPortalApi.baseUrl = 'http://127.0.0.1:8787';`
class GymPortalApi {
  static String? baseUrl;

  Uri? _uri(String path) {
    final base = baseUrl;
    if (base == null || base.isEmpty) return null;
    return Uri.parse('$base$path');
  }

  Future<GymPortalUnitPublic?> fetchUnitPublic(String unitId) async {
    final uri = _uri('/api/units/$unitId/public');
    if (uri == null) return null;

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) return null;
      final body = await res.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      final unit = map['unit'] as Map<String, dynamic>;
      return GymPortalUnitPublic.fromJson(
        networkId: map['networkId'] as String,
        networkName: map['networkName'] as String,
        unit: unit,
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> issueDailyPassCode({
    required String code,
    required String unitId,
    required String holderName,
    required DateTime validUntil,
  }) async {
    final uri = _uri('/api/check-ins/issue');
    if (uri == null) return false;

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'code': code,
          'unitId': unitId,
          'holderName': holderName,
          'validUntil': validUntil.toIso8601String(),
          'type': 'daily_pass',
        }),
      );
      final res = await req.close();
      return res.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}

class GymPortalUnitPublic {
  GymPortalUnitPublic({
    required this.networkId,
    required this.networkName,
    required this.id,
    required this.unitName,
    required this.dailyPassPrice,
    required this.dailyPassActive,
    required this.modalities,
    required this.dailyPassModalities,
    required this.hasHeroPhoto,
    required this.galleryCount,
  });

  final String networkId;
  final String networkName;
  final String id;
  final String unitName;
  final double dailyPassPrice;
  final bool dailyPassActive;
  final List<String> modalities;
  final List<String> dailyPassModalities;
  final bool hasHeroPhoto;
  final int galleryCount;

  factory GymPortalUnitPublic.fromJson({
    required String networkId,
    required String networkName,
    required Map<String, dynamic> unit,
  }) {
    return GymPortalUnitPublic(
      networkId: networkId,
      networkName: networkName,
      id: unit['id'] as String,
      unitName: unit['unitName'] as String,
      dailyPassPrice: (unit['dailyPassPrice'] as num).toDouble(),
      dailyPassActive: unit['dailyPassActive'] as bool? ?? true,
      modalities: (unit['modalities'] as List<dynamic>).cast<String>(),
      dailyPassModalities:
          (unit['dailyPassModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      hasHeroPhoto: unit['hasHeroPhoto'] as bool? ?? false,
      galleryCount: unit['galleryCount'] as int? ?? 0,
    );
  }
}
