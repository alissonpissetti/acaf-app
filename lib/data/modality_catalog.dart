import 'mock_gyms.dart';

/// Catálogo base de modalidades (API futura). Unidades podem acrescentar outras.
const List<String> baseModalityCatalog = [
  '24h',
  'Alongamento',
  'Aulas em grupo',
  'Box',
  'Cardio',
  'Cross Training',
  'Dança',
  'Funcional',
  'HIIT',
  'Hidroginástica',
  'Lutas',
  'Meditação',
  'Musculação',
  'Olympic lifting',
  'Personal trainer',
  'Pilates',
  'Spinning',
  'Yoga',
];

/// Todas as modalidades conhecidas (catálogo + mocks), ordenadas. `24h` primeiro.
List<String> allModalityOptions() {
  final options = <String>{
    ...baseModalityCatalog,
    for (final gym in mockGyms) ...gym.modalities,
  };
  final sorted = options.where((o) => o != '24h').toList()..sort((a, b) => a.compareTo(b));
  return ['24h', ...sorted];
}

String modalityFilterLabel(String key) {
  if (key == '24h') return 'Aberto 24 horas';
  return key;
}

bool modalityFilterMatchesQuery(String key, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return modalityFilterLabel(key).toLowerCase().contains(q) || key.toLowerCase().contains(q);
}
