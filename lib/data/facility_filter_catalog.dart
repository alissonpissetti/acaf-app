import '../models/gym.dart';

class FacilityFilterOption {
  const FacilityFilterOption({
    required this.key,
    required this.label,
    required this.match,
  });

  final String key;
  final String label;
  final bool Function(Gym gym) match;
}

/// Estrutura física da unidade.
abstract final class FacilityFilterCatalog {
  static const structureOptions = <FacilityFilterOption>[
    FacilityFilterOption(
      key: 'pool',
      label: 'Piscina',
      match: _hasPool,
    ),
    FacilityFilterOption(
      key: 'parking',
      label: 'Estacionamento',
      match: _hasParking,
    ),
    FacilityFilterOption(
      key: 'lockers',
      label: 'Armários',
      match: _hasLockers,
    ),
    FacilityFilterOption(
      key: 'showers',
      label: 'Chuveiro quente',
      match: _hasHotShower,
    ),
    FacilityFilterOption(
      key: 'ac',
      label: 'Ar-condicionado',
      match: _hasAc,
    ),
    FacilityFilterOption(
      key: 'accessibility',
      label: 'Acessibilidade',
      match: _hasAccessibility,
    ),
    FacilityFilterOption(
      key: 'bike_rack',
      label: 'Bicicletário',
      match: _hasBikeRack,
    ),
  ];

  /// Vantagens e serviços.
  static const advantageOptions = <FacilityFilterOption>[
    FacilityFilterOption(
      key: 'open_24h',
      label: 'Aberto 24 horas',
      match: _open24h,
    ),
    FacilityFilterOption(
      key: 'wifi',
      label: 'Wi-Fi',
      match: _hasWifi,
    ),
    FacilityFilterOption(
      key: 'towel',
      label: 'Toalha inclusa',
      match: _hasTowel,
    ),
    FacilityFilterOption(
      key: 'sauna',
      label: 'Sauna',
      match: _hasSauna,
    ),
    FacilityFilterOption(
      key: 'recovery',
      label: 'Área recovery',
      match: _hasRecovery,
    ),
    FacilityFilterOption(
      key: 'cafe',
      label: 'Café / lanchonete',
      match: _hasCafe,
    ),
    FacilityFilterOption(
      key: 'kids',
      label: 'Espaço kids',
      match: _hasKids,
    ),
    FacilityFilterOption(
      key: 'water',
      label: 'Bebedouros',
      match: _hasWater,
    ),
  ];

  static FacilityFilterOption? optionByKey(String key) {
    for (final o in [...structureOptions, ...advantageOptions]) {
      if (o.key == key) return o;
    }
    return null;
  }

  static String labelForKey(String key) => optionByKey(key)?.label ?? key;

  static bool _labelContains(Gym gym, String needle) {
    final n = needle.toLowerCase();
    return gym.facilities.any((f) => f.label.toLowerCase().contains(n));
  }

  static bool _hasPool(Gym gym) => _labelContains(gym, 'piscina');
  static bool _hasParking(Gym gym) => _labelContains(gym, 'estacionamento');
  static bool _hasLockers(Gym gym) => _labelContains(gym, 'armário');
  static bool _hasHotShower(Gym gym) => _labelContains(gym, 'chuveiro');
  static bool _hasAc(Gym gym) => _labelContains(gym, 'condicionado');
  static bool _hasAccessibility(Gym gym) => _labelContains(gym, 'acessibilidade');
  static bool _hasBikeRack(Gym gym) => _labelContains(gym, 'biciclet');
  static bool _hasWifi(Gym gym) => _labelContains(gym, 'wi-fi') || _labelContains(gym, 'wifi');
  static bool _hasTowel(Gym gym) => _labelContains(gym, 'toalha');
  static bool _hasSauna(Gym gym) => _labelContains(gym, 'sauna');
  static bool _hasRecovery(Gym gym) => _labelContains(gym, 'recovery');
  static bool _hasCafe(Gym gym) => _labelContains(gym, 'café') || _labelContains(gym, 'lanchonete');
  static bool _hasKids(Gym gym) => _labelContains(gym, 'kids');
  static bool _hasWater(Gym gym) => _labelContains(gym, 'bebedouro');
  static bool _open24h(Gym gym) {
    if (gym.openHours.toLowerCase().contains('24')) return true;
    return _labelContains(gym, '24h');
  }
}
