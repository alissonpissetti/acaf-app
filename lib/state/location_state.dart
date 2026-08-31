import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/search_areas.dart';
import '../state/catalog_state.dart';

/// Localização do usuário para ordenar unidades por distância.
class LocationState extends ChangeNotifier {
  LocationState(this._catalog);

  final CatalogState _catalog;

  bool _loading = true;
  String _currentLocationLabel = '';
  bool _usingCurrentLocation = true;
  SearchArea? _manualArea;
  double? _lastLatitude;
  double? _lastLongitude;

  bool get loading => _loading;

  bool get usingCurrentLocation => _usingCurrentLocation;

  SearchArea? get manualArea => _manualArea;

  List<SearchArea> get availableAreas {
    final cities = _catalog.repository.cities;
    if (cities.isEmpty) {
      return searchAreasFromCities(['Curitiba']);
    }
    return searchAreasFromCities(cities);
  }

  String get currentLocationLabel {
    if (_loading) return 'Atualizando...';
    return _currentLocationLabel.isEmpty ? 'Curitiba, PR' : _currentLocationLabel;
  }

  String get areaLabel {
    if (_loading && _usingCurrentLocation) return 'Obtendo localização...';
    if (_usingCurrentLocation) return currentLocationLabel;
    return _manualArea?.label ?? currentLocationLabel;
  }

  String get cityFilter {
    if (_usingCurrentLocation) {
      return _inferCityFromGpsLabel(_currentLocationLabel);
    }
    return _manualArea?.cityMatch ?? 'Curitiba';
  }

  /// Sem filtro de cidade quando a lista usa GPS (ordena por distância).
  String? get listCityFilter {
    if (_usingCurrentLocation) return null;
    return _manualArea?.cityMatch ?? 'Curitiba';
  }

  Future<void> resolveNearbyArea() async {
    _loading = true;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentLocationLabel = 'Curitiba, PR';
        _loading = false;
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _currentLocationLabel = 'Curitiba, PR';
        _loading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;
      _catalog.repository.applyDistancesFrom(position.latitude, position.longitude);
      _currentLocationLabel = 'Perto de você';
    } catch (e) {
      debugPrint('Connect: falha ao obter localização: $e');
      _currentLocationLabel = 'Curitiba, PR';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    _usingCurrentLocation = true;
    _manualArea = null;
    await resolveNearbyArea();
  }

  void selectArea(SearchArea area) {
    _usingCurrentLocation = false;
    _manualArea = area;
    _loading = false;
    notifyListeners();
  }

  /// Recalcula distâncias após o catálogo ser recarregado (coordenadas novas na API).
  void refreshDistancesFromCache() {
    if (_lastLatitude == null || _lastLongitude == null) return;
    _catalog.repository.applyDistancesFrom(_lastLatitude!, _lastLongitude!);
    notifyListeners();
  }

  static String _inferCityFromGpsLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('são paulo') || lower.contains('sao paulo')) return 'São Paulo';
    if (lower.contains('florianópolis') || lower.contains('florianopolis')) return 'Florianópolis';
    if (lower.contains('joinville')) return 'Joinville';
    return 'Curitiba';
  }
}
