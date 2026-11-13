import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../data/unit_subscription_plans.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../services/connect_api.dart';

class CatalogRepository {
  CatalogRepository({ConnectApi? api}) : _api = api ?? ConnectApi();

  final ConnectApi _api;

  List<Gym> _gyms = [];
  List<GymNetwork> _networks = [];
  List<String> _cities = [];
  bool _loaded = false;
  String? _loadError;

  List<Gym> get gyms => List.unmodifiable(_gyms);
  List<GymNetwork> get networks => List.unmodifiable(_networks);
  List<String> get cities => List.unmodifiable(_cities);
  bool get isLoaded => _loaded;
  String? get loadError => _loadError;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await reload();
  }

  Future<void> reload() async {
    _loadError = null;
    try {
      final catalog = await _api.fetchCatalog();
      if (catalog == null) {
        throw StateError('Não foi possível carregar o catálogo da API.');
      }

      final networkRows = catalog['networks'] as List<dynamic>? ?? const [];
      _networks = networkRows
          .map((row) => _mapNetwork(row as Map<String, dynamic>))
          .toList();

      final unitRows = catalog['units'] as List<dynamic>? ?? const [];
      _gyms = unitRows
          .map((row) => _mapUnit(row as Map<String, dynamic>))
          .toList();

      _cities = await _api.fetchCatalogCities();
      _loaded = true;
    } catch (e) {
      _loadError = e is StateError ? e.message : 'Falha ao carregar academias.';
      _loaded = false;
      throw StateError(_loadError!);
    }
  }

  GymNetwork _mapNetwork(Map<String, dynamic> row) {
    final logoUrl = row['logoUrl'] as String?;
    return GymNetwork(
      id: row['id'] as String,
      name: row['name'] as String,
      brandLogoUrl: logoUrl != null && logoUrl.isNotEmpty ? ApiConfig.absoluteUrl(logoUrl) : null,
    );
  }

  Gym _mapUnit(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final networkId = row['networkId'] as String;
    final modalities = (row['modalities'] as List<dynamic>).cast<String>();
    final planSpecs = _mapPlanSpecs(row['planSpecs'] as List<dynamic>? ?? const []);

    final heroPath = row['heroPhotoUrl'] as String?;
    final galleryPaths = (row['galleryPhotoUrls'] as List<dynamic>?)?.cast<String>() ?? const [];

    final gym = Gym(
      id: id,
      networkId: networkId,
      name: row['unitName'] as String,
      neighborhood: row['neighborhood'] as String,
      city: row['city'] as String,
      rating: 0,
      distanceKm: 0,
      modalities: modalities,
      facilities: const [],
      openHours: row['openHours'] as String? ?? '',
      dailyPassPrice: (row['dailyPassPrice'] as num).toDouble(),
      dailyPassModalities:
          (row['dailyPassModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      dailyPassActive: row['dailyPassActive'] as bool? ?? true,
      planSpecs: planSpecs,
      scheduledModalities:
          (row['scheduledModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      weeklySchedule: row['weeklySchedule'] as Map<String, dynamic>?,
      plans: const [],
      heroTint: _tintForNetwork(networkId),
      heroIcon: Icons.fitness_center_rounded,
      heroImageUrl: heroPath != null ? ApiConfig.absoluteUrl(heroPath) : null,
      galleryImageUrls: galleryPaths.map(ApiConfig.absoluteUrl).toList(),
      brandLogoUrl: row['networkLogoUrl'] != null
          ? ApiConfig.absoluteUrl(row['networkLogoUrl'] as String)
          : null,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      description: _trimOrNull(row['description'] as String?),
    );

    return gym.copyWith(
      plans: buildUnitConnectPlans(gym: gym),
    );
  }

  List<UnitPlanSpec> _mapPlanSpecs(List<dynamic> rows) {
    return rows.map((raw) {
      final row = raw as Map<String, dynamic>;
      return UnitPlanSpec(
        connectPlanId: row['connectPlanId'] as String,
        includedModalities:
            (row['includedModalities'] as List<dynamic>?)?.cast<String>() ?? const [],
        exactOnly: row['exactOnly'] as bool? ?? false,
      );
    }).toList();
  }

  static Color _tintForNetwork(String networkId) {
    const palette = [
      Color(0xFFE8881C),
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFF9333EA),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    final hash = networkId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return palette[hash % palette.length];
  }

  Gym? gymById(String id) {
    for (final gym in _gyms) {
      if (gym.id == id) return gym;
    }
    return null;
  }

  GymNetwork? networkById(String id) {
    for (final network in _networks) {
      if (network.id == id) return network;
    }
    return null;
  }

  GymNetwork networkForUnit(Gym unit) {
    return networkById(unit.networkId) ??
        GymNetwork(id: unit.networkId, name: unit.name);
  }

  List<Gym> unitsForNetwork(String networkId) {
    return _gyms.where((g) => g.networkId == networkId).toList();
  }

  void applyDistancesFrom(double latitude, double longitude) {
    _gyms = _gyms
        .map((gym) {
          if (gym.latitude == null || gym.longitude == null) return gym;
          final km = _distanceKm(latitude, longitude, gym.latitude!, gym.longitude!);
          return gym.copyWith(distanceKm: km);
        })
        .toList();
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadiusKm * c * 10).round() / 10;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
