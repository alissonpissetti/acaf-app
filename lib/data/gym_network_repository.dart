import '../models/gym.dart';
import '../models/gym_network.dart';
import '../state/catalog_state.dart';

class GymNetworkRepository {
  GymNetworkRepository(this._catalog);

  final CatalogState _catalog;

  GymNetwork? networkById(String id) => _catalog.repository.networkById(id);

  GymNetwork networkForUnit(Gym unit) => _catalog.repository.networkForUnit(unit);

  List<Gym> unitsForNetwork(String networkId) {
    final units = _catalog.repository.unitsForNetwork(networkId)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return units;
  }

  int unitCount(String networkId) => unitsForNetwork(networkId).length;
}
