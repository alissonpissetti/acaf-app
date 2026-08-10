import '../models/gym.dart';

/// Modalidades da diária configuradas no painel da academia (mock por unidade).
const Map<String, List<String>> _dailyPassModalityOverrides = {
  'g_carpe': ['Musculação', 'Funcional', 'Natação', 'Full Body'],
  'g_carpe_batel': ['Musculação', 'Funcional'],
  'g_viver': ['Musculação', 'Cardio', 'Natação'],
  'g_equilibrium': ['Musculação', 'Funcional', 'Alongamento'],
  'g_wolf': ['Musculação', 'Funcional'],
  'g4': ['Musculação'],
  'g2': ['Cross Training', 'Box', 'HIIT'],
  'g3': ['Yoga', 'Pilates'],
};

List<String> _filterToUnit(List<String> names, List<String> unitModalities) {
  return names
      .where((m) => unitModalities.any((u) => u.toLowerCase() == m.toLowerCase()))
      .toList();
}

List<String> resolveDailyPassModalities(String gymId, List<String> unitModalities) {
  final override = _dailyPassModalityOverrides[gymId];
  if (override != null && override.isNotEmpty) {
    return _filterToUnit(override, unitModalities);
  }
  if (unitModalities.length <= 3) return List<String>.from(unitModalities);
  return unitModalities.take(3).toList();
}

Gym applyDailyPassModalitiesToGym(Gym gym) {
  if (gym.dailyPassModalities.isNotEmpty) {
    return gym;
  }
  final configured = resolveDailyPassModalities(gym.id, gym.modalities);
  return gym.copyWith(dailyPassModalities: configured);
}

List<Gym> applyDailyPassModalitiesToAll(List<Gym> gyms) {
  return gyms.map(applyDailyPassModalitiesToGym).toList();
}
