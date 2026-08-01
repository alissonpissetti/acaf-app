import '../models/gym.dart';
import '../models/gym_network.dart';
import 'mock_gym_networks.dart';
import 'mock_gyms.dart';

class GymNetworkRepository {
  GymNetwork? networkById(String id) => gymNetworkById(id);

  GymNetwork networkForUnit(Gym unit) {
    return gymNetworkById(unit.networkId) ??
        GymNetwork(id: unit.networkId, name: unit.name);
  }

  List<Gym> unitsForNetwork(String networkId) {
    final units = mockGyms.where((g) => g.networkId == networkId).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return units;
  }

  int unitCount(String networkId) => unitsForNetwork(networkId).length;
}
