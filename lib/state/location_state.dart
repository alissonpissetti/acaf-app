import 'package:flutter/foundation.dart';

import '../data/mock_search_areas.dart';

/// Localização para listar associados por perto (GPS mock + escolha manual de área).
class LocationState extends ChangeNotifier {
  bool _loading = true;
  String _currentLocationLabel = '';
  bool _usingCurrentLocation = true;
  SearchArea? _manualArea;

  bool get loading => _loading;

  bool get usingCurrentLocation => _usingCurrentLocation;

  SearchArea? get manualArea => _manualArea;

  /// Rótulo do GPS (sem área manual selecionada).
  String get currentLocationLabel {
    if (_loading) return 'Atualizando...';
    return _currentLocationLabel.isEmpty ? 'Curitiba, PR' : _currentLocationLabel;
  }

  /// Texto exibido no campo de localização.
  String get areaLabel {
    if (_loading && _usingCurrentLocation) return 'Obtendo localização...';
    if (_usingCurrentLocation) return currentLocationLabel;
    return _manualArea?.label ?? currentLocationLabel;
  }

  /// Filtro de cidade para o repositório de associados.
  String get cityFilter {
    if (_usingCurrentLocation) {
      return _inferCityFromGpsLabel(_currentLocationLabel);
    }
    return _manualArea?.cityMatch ?? 'Curitiba';
  }

  Future<void> resolveNearbyArea() async {
    _loading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 450));
    _currentLocationLabel = 'Curitiba, PR';
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

  static String _inferCityFromGpsLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('são paulo') || lower.contains('sao paulo')) return 'São Paulo';
    if (lower.contains('florianópolis') || lower.contains('florianopolis')) return 'Florianópolis';
    if (lower.contains('joinville')) return 'Joinville';
    return 'Curitiba';
  }
}
