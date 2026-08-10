import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/daily_pass_offer.dart';
import '../models/modality_schedule.dart';

/// Cliente HTTP da acaf-api para o app associado.
class AcafApi {
  AcafApi({String? baseUrl}) : _baseUrl = (baseUrl ?? ApiConfig.resolveBaseUrl()).replaceAll(RegExp(r'/+$'), '');

  final String _baseUrl;

  Uri? _uri(String apiPath) {
    if (apiPath.startsWith('/api/')) {
      return Uri.parse('$_baseUrl$apiPath');
    }
    final normalized = apiPath.startsWith('/') ? apiPath : '/$apiPath';
    return Uri.parse('$_baseUrl/api$normalized');
  }

  Future<Map<String, dynamic>?> _getJson(String apiPath) async {
    final uri = _uri(apiPath);
    if (uri == null) return null;
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) return null;
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> fetchDomain() => _getJson('/domain');

  Future<EnrollmentValidationResult> validateEnrollmentCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const EnrollmentValidationResult(
        ok: false,
        errorMessage: 'Informe o código de adesão.',
      );
    }
    final uri = _uri(
      '/connect/enrollment/validate?code=${Uri.encodeQueryComponent(trimmed)}',
    );
    if (uri == null) {
      return const EnrollmentValidationResult(
        ok: false,
        errorMessage: 'API indisponível.',
      );
    }
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != HttpStatus.ok) {
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final raw = parsed['message'];
          final message = raw is String
              ? raw
              : (raw is Map ? raw['message'] as String? : null) ??
                  'Código inválido ou expirado.';
          return EnrollmentValidationResult(ok: false, errorMessage: message);
        } catch (_) {
          return const EnrollmentValidationResult(
            ok: false,
            errorMessage: 'Código inválido ou expirado.',
          );
        }
      }
      final map = jsonDecode(body) as Map<String, dynamic>;
      return EnrollmentValidationResult(
        ok: true,
        companyName: map['companyName'] as String?,
        code: map['code'] as String?,
        hint: map['hint'] as String?,
      );
    } catch (_) {
      return const EnrollmentValidationResult(
        ok: false,
        errorMessage: 'Falha de conexão com o servidor.',
      );
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> fetchCatalog({String? city, String? q}) async {
    final params = <String>[];
    if (city != null && city.trim().isNotEmpty) {
      params.add('city=${Uri.encodeQueryComponent(city.trim())}');
    }
    if (q != null && q.trim().isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(q.trim())}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return _getJson('/catalog$query');
  }

  Future<List<String>> fetchCatalogCities() async {
    final map = await _getJson('/catalog/cities');
    if (map == null) return const [];
    return (map['cities'] as List<dynamic>?)?.cast<String>() ?? const [];
  }

  Future<GymPortalUnitPublic?> fetchUnitPublic(String unitId) async {
    final map = await _getJson('/units/$unitId/public');
    if (map == null) return null;
    final unit = map['unit'] as Map<String, dynamic>;
    return GymPortalUnitPublic.fromJson(
      networkId: map['networkId'] as String,
      networkName: map['networkName'] as String,
      scheduledModalities:
          (map['scheduledModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      unit: unit,
    );
  }

  Future<ModalityAvailabilityFetchResult> fetchModalityAvailability({
    required String unitId,
    required String from,
    required String to,
    String? modality,
  }) async {
    final baseUri = _uri('/units/$unitId/modality-availability');
    if (baseUri == null) {
      return const ModalityAvailabilityFetchResult(
        ok: false,
        errorMessage: 'API indisponível.',
      );
    }

    final params = <String, String>{'from': from, 'to': to};
    final modalityTrimmed = modality?.trim();
    if (modalityTrimmed != null && modalityTrimmed.isNotEmpty) {
      params['modality'] = modalityTrimmed;
    }
    final uri = baseUri.replace(queryParameters: params);

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != HttpStatus.ok) {
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final raw = parsed['message'];
          final message = raw is String
              ? raw
              : (raw is Map ? raw['message'] as String? : null) ??
                  'Não foi possível carregar os horários.';
          return ModalityAvailabilityFetchResult(ok: false, errorMessage: message);
        } catch (_) {
          return const ModalityAvailabilityFetchResult(
            ok: false,
            errorMessage: 'Não foi possível carregar os horários.',
          );
        }
      }

      final map = jsonDecode(body) as Map<String, dynamic>;
      final slots = (map['slots'] as List<dynamic>? ?? const [])
          .map((item) => ModalityAvailabilitySlot.fromJson(item as Map<String, dynamic>))
          .where((slot) => slot.occurrenceKey.isNotEmpty && slot.occurrenceDate.isNotEmpty)
          .toList();
      return ModalityAvailabilityFetchResult(ok: true, slots: slots);
    } catch (_) {
      return const ModalityAvailabilityFetchResult(
        ok: false,
        errorMessage: 'Falha de conexão com o servidor.',
      );
    } finally {
      client.close();
    }
  }

  Future<ReservationCreateResult> createReservation({
    required String unitId,
    required String occurrenceDate,
    String? slotTemplateId,
    String? overrideId,
    required String holderName,
  }) async {
    final uri = _uri('/modality-reservations');
    if (uri == null) {
      return const ReservationCreateResult(
        ok: false,
        errorMessage: 'API indisponível.',
      );
    }
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'unitId': unitId,
          'occurrenceDate': occurrenceDate,
          if (slotTemplateId != null) 'slotTemplateId': slotTemplateId,
          if (overrideId != null) 'overrideId': overrideId,
          'holderName': holderName,
        }),
      );
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != HttpStatus.ok && res.statusCode != HttpStatus.created) {
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final raw = parsed['message'];
          final message = raw is String
              ? raw
              : (raw is Map ? raw['message'] as String? : null) ??
                  'Não foi possível reservar este horário.';
          return ReservationCreateResult(ok: false, errorMessage: message);
        } catch (_) {
          return const ReservationCreateResult(
            ok: false,
            errorMessage: 'Não foi possível reservar este horário.',
          );
        }
      }
      return ReservationCreateResult(
        ok: true,
        reservation: ModalityReservation.fromJson(jsonDecode(body) as Map<String, dynamic>),
      );
    } catch (_) {
      return const ReservationCreateResult(
        ok: false,
        errorMessage: 'Falha de conexão com o servidor.',
      );
    } finally {
      client.close();
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    final uri = _uri('/modality-reservations/$reservationId');
    if (uri == null) return false;
    final client = HttpClient();
    try {
      final req = await client.deleteUrl(uri);
      final res = await req.close();
      return res.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<List<ModalityReservation>> fetchMyReservations(String holderName) async {
    final map = await _getJson(
      '/modality-reservations?holderName=${Uri.encodeQueryComponent(holderName)}',
    );
    if (map == null) return const [];
    final rows = map['reservations'] as List<dynamic>? ?? const [];
    return rows
        .map((item) => ModalityReservation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DailyPassOffersResponse?> fetchDailyPassOffers({
    required String unitId,
    required String date,
  }) async {
    final map = await _getJson('/units/$unitId/daily-pass-offers?date=$date');
    if (map == null) return null;
    return DailyPassOffersResponse.fromJson(map);
  }

  Future<GeoCheckInApiResult> requestGeoCheckIn({
    required String unitId,
    required String code,
    required String holderName,
    required double latitude,
    required double longitude,
  }) async {
    final uri = _uri('/check-ins/request');
    if (uri == null) {
      return const GeoCheckInApiResult(ok: false, message: 'API indisponível.');
    }
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'unitId': unitId,
          'code': code,
          'holderName': holderName,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      try {
        final parsed = jsonDecode(body) as Map<String, dynamic>;
        if (parsed['ok'] == true) {
          final msg = parsed['message'];
          return GeoCheckInApiResult(
            ok: true,
            message: msg is String ? msg : 'Check-in liberado automaticamente.',
          );
        }
        if (res.statusCode != HttpStatus.ok) {
          final raw = parsed['message'];
          final message = raw is String
              ? raw
              : (raw is Map ? raw['message'] as String? : null) ??
                  'Não foi possível fazer check-in.';
          return GeoCheckInApiResult(ok: false, message: message);
        }
      } catch (_) {
        if (res.statusCode != HttpStatus.ok) {
          return const GeoCheckInApiResult(ok: false, message: 'Não foi possível fazer check-in.');
        }
      }
      return const GeoCheckInApiResult(ok: true, message: 'Check-in liberado automaticamente.');
    } catch (_) {
      return const GeoCheckInApiResult(ok: false, message: 'Falha de conexão com o servidor.');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _putJson(String apiPath, Map<String, dynamic> body) async {
    final uri = _uri(apiPath);
    if (uri == null) return null;
    final client = HttpClient();
    try {
      final req = await client.putUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != HttpStatus.ok) {
        try {
          final parsed = jsonDecode(text) as Map<String, dynamic>;
          return {'ok': false, 'message': _messageFromBody(parsed)};
        } catch (_) {
          return {'ok': false, 'message': 'Não foi possível completar a operação.'};
        }
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _messageFromBody(Map<String, dynamic> parsed) {
    final raw = parsed['message'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    if (raw is List && raw.isNotEmpty) return raw.map((e) => e.toString()).join(', ');
    final nested = parsed['message'];
    if (nested is Map && nested['message'] is String) return nested['message'] as String;
    return 'Não foi possível completar a operação.';
  }

  Future<List<ActiveDailyPassCode>> fetchActiveDailyPasses(String holderName) async {
    final trimmed = holderName.trim();
    if (trimmed.isEmpty) return const [];
    final map = await _getJson(
      '/connect/daily-passes?holderName=${Uri.encodeQueryComponent(trimmed)}',
    );
    if (map == null) return const [];
    final rows = map['passes'] as List<dynamic>? ?? const [];
    return rows
        .map((item) => ActiveDailyPassCode.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ConnectMemberProfile?> fetchConnectMember(String holderName) async {
    final trimmed = holderName.trim();
    if (trimmed.isEmpty) return null;
    final map = await _getJson(
      '/connect/member?holderName=${Uri.encodeQueryComponent(trimmed)}',
    );
    if (map == null) return null;
    final profile = map['profile'];
    if (profile is! Map<String, dynamic>) return null;
    return ConnectMemberProfile.fromJson(profile);
  }

  Future<ConnectMemberApiResult> registerConnectSubscription({
    required String holderName,
    required String connectPlanId,
    String? companyName,
  }) async {
    final map = await _putJson('/connect/subscription', {
      'holderName': holderName.trim(),
      'connectPlanId': connectPlanId,
      if (companyName != null && companyName.trim().isNotEmpty) 'companyName': companyName.trim(),
      'active': true,
    });
    if (map == null) {
      return const ConnectMemberApiResult(ok: false, errorMessage: 'API indisponível.');
    }
    if (map['ok'] != true) {
      return ConnectMemberApiResult(ok: false, errorMessage: _messageFromBody(map));
    }
    final profile = map['profile'];
    if (profile is! Map<String, dynamic>) {
      return const ConnectMemberApiResult(ok: false, errorMessage: 'Resposta inválida da API.');
    }
    return ConnectMemberApiResult(
      ok: true,
      profile: ConnectMemberProfile.fromJson(profile),
    );
  }

  Future<ConnectMemberApiResult> setConnectPrimaryGym({
    required String holderName,
    required String unitId,
  }) async {
    final map = await _putJson('/connect/primary-gym', {
      'holderName': holderName.trim(),
      'unitId': unitId,
    });
    if (map == null) {
      return const ConnectMemberApiResult(ok: false, errorMessage: 'API indisponível.');
    }
    if (map['ok'] != true) {
      return ConnectMemberApiResult(ok: false, errorMessage: _messageFromBody(map));
    }
    final profile = map['profile'];
    if (profile is! Map<String, dynamic>) {
      return const ConnectMemberApiResult(ok: false, errorMessage: 'Resposta inválida da API.');
    }
    return ConnectMemberApiResult(
      ok: true,
      profile: ConnectMemberProfile.fromJson(profile),
    );
  }

  Future<bool> issueDailyPassCode({
    required String code,
    required String unitId,
    required String holderName,
    required DateTime validUntil,
    String? offerId,
    String? occurrenceDate,
  }) async {
    final uri = _uri('/check-ins/issue');
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
          if (offerId != null) 'offerId': offerId,
          if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
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

class GeoCheckInApiResult {
  const GeoCheckInApiResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

class ModalityAvailabilityFetchResult {
  const ModalityAvailabilityFetchResult({
    required this.ok,
    this.slots = const [],
    this.errorMessage,
  });

  final bool ok;
  final List<ModalityAvailabilitySlot> slots;
  final String? errorMessage;
}

class ReservationCreateResult {
  const ReservationCreateResult({
    required this.ok,
    this.reservation,
    this.errorMessage,
  });

  final bool ok;
  final ModalityReservation? reservation;
  final String? errorMessage;
}

class EnrollmentValidationResult {
  const EnrollmentValidationResult({
    required this.ok,
    this.companyName,
    this.code,
    this.hint,
    this.errorMessage,
  });

  final bool ok;
  final String? companyName;
  final String? code;
  final String? hint;
  final String? errorMessage;
}

class ConnectMemberProfile {
  const ConnectMemberProfile({
    required this.holderName,
    required this.connectPlanId,
    required this.active,
    required this.since,
    this.primaryUnitId,
    this.primaryUnitName,
    this.primaryChosenAt,
    this.primaryFirstCheckInAt,
    this.primaryCheckInsSinceFirst = 0,
    this.canChangePrimary = true,
    this.remainingCheckInsBeforeChange = 0,
    this.minCheckInsToChange = 12,
  });

  final String holderName;
  final String connectPlanId;
  final bool active;
  final String since;
  final String? primaryUnitId;
  final String? primaryUnitName;
  final String? primaryChosenAt;
  final String? primaryFirstCheckInAt;
  final int primaryCheckInsSinceFirst;
  final bool canChangePrimary;
  final int remainingCheckInsBeforeChange;
  final int minCheckInsToChange;

  factory ConnectMemberProfile.fromJson(Map<String, dynamic> json) {
    return ConnectMemberProfile(
      holderName: json['holderName'] as String? ?? '',
      connectPlanId: json['connectPlanId'] as String? ?? 'connect-start',
      active: json['active'] as bool? ?? false,
      since: json['since'] as String? ?? '',
      primaryUnitId: json['primaryUnitId'] as String?,
      primaryUnitName: json['primaryUnitName'] as String?,
      primaryChosenAt: json['primaryChosenAt'] as String?,
      primaryFirstCheckInAt: json['primaryFirstCheckInAt'] as String?,
      primaryCheckInsSinceFirst: (json['primaryCheckInsSinceFirst'] as num?)?.toInt() ?? 0,
      canChangePrimary: json['canChangePrimary'] as bool? ?? true,
      remainingCheckInsBeforeChange: (json['remainingCheckInsBeforeChange'] as num?)?.toInt() ?? 0,
      minCheckInsToChange: (json['minCheckInsToChange'] as num?)?.toInt() ?? 12,
    );
  }
}

class ConnectMemberApiResult {
  const ConnectMemberApiResult({
    required this.ok,
    this.profile,
    this.errorMessage,
  });

  final bool ok;
  final ConnectMemberProfile? profile;
  final String? errorMessage;
}

class ActiveDailyPassCode {
  const ActiveDailyPassCode({
    required this.code,
    required this.unitId,
    required this.holderName,
    required this.validUntil,
    this.pricePaid,
    this.allowedModalities = const [],
    this.validWindowStart,
    this.validWindowEnd,
    this.occurrenceDate,
  });

  final String code;
  final String unitId;
  final String holderName;
  final String validUntil;
  final double? pricePaid;
  final List<String> allowedModalities;
  final String? validWindowStart;
  final String? validWindowEnd;
  final String? occurrenceDate;

  factory ActiveDailyPassCode.fromJson(Map<String, dynamic> json) {
    return ActiveDailyPassCode(
      code: json['code'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      holderName: json['holderName'] as String? ?? '',
      validUntil: json['validUntil'] as String? ?? '',
      pricePaid: (json['pricePaid'] as num?)?.toDouble(),
      allowedModalities:
          (json['allowedModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      validWindowStart: json['validWindowStart'] as String?,
      validWindowEnd: json['validWindowEnd'] as String?,
      occurrenceDate: json['occurrenceDate'] as String?,
    );
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
    required this.scheduledModalities,
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
  final List<String> scheduledModalities;

  factory GymPortalUnitPublic.fromJson({
    required String networkId,
    required String networkName,
    required Map<String, dynamic> unit,
    List<String> scheduledModalities = const [],
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
      scheduledModalities: scheduledModalities,
    );
  }
}
