import '../models/gym.dart';
List<String> resolveDailyPassModalities(String gymId, List<String> unitModalities) {
  if (unitModalities.isEmpty) return const [];
  return List<String>.from(unitModalities);
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
