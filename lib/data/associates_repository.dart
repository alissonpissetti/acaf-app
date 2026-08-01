import '../models/associate_search_filters.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import 'facility_filter_catalog.dart';
import 'gym_network_repository.dart';
import 'mock_gyms.dart';

/// Fonte de associados da rede ACAF (mock — substituir por API).
class AssociatesRepository {
  static const homePageSize = 10;

  final _networks = GymNetworkRepository();

  GymNetwork? networkById(String id) => _networks.networkById(id);

  GymNetwork networkForUnit(Gym gym) => _networks.networkForUnit(gym);

  int networkUnitCount(String networkId) => _networks.unitCount(networkId);
  Gym? gymById(String id) {
    for (final gym in mockGyms) {
      if (gym.id == id) return gym;
    }
    return null;
  }

  List<Gym> nearbyAssociates() {
    final sorted = [...mockGyms]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return sorted;
  }

  List<Gym> searchNearby({
    required String query,
    Set<String> modalityFilters = const {},
    String cityFilter = 'Curitiba',
    double? minRating,
    Set<String> structureKeys = const {},
    Set<String> advantageKeys = const {},
  }) {
    return searchWithFilters(
      filters: AssociateSearchFilters(
        query: query,
        modalities: modalityFilters,
        minRating: minRating,
        structureKeys: structureKeys,
        advantageKeys: advantageKeys,
      ),
      cityFilter: cityFilter,
    );
  }

  List<Gym> searchWithFilters({
    required AssociateSearchFilters filters,
    String cityFilter = 'Curitiba',
  }) {
    var list = nearbyAssociates().where((g) => g.city.contains(cityFilter)).toList();

    if (filters.minRating != null) {
      list = list.where((g) => g.rating >= filters.minRating!).toList();
    }

    if (filters.modalities.isNotEmpty) {
      list = list
          .where((g) => filters.modalities.any((filter) => _matchesModalityFilter(g, filter)))
          .toList();
    }

    for (final key in filters.structureKeys) {
      final opt = FacilityFilterCatalog.optionByKey(key);
      if (opt != null) {
        list = list.where(opt.match).toList();
      }
    }

    for (final key in filters.advantageKeys) {
      final opt = FacilityFilterCatalog.optionByKey(key);
      if (opt != null) {
        list = list.where(opt.match).toList();
      }
    }

    final q = filters.query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((gym) {
      final network = _networks.networkForUnit(gym);
      return gym.name.toLowerCase().contains(q) ||
          network.name.toLowerCase().contains(q) ||
          gym.neighborhood.toLowerCase().contains(q) ||
          gym.modalities.any((m) => m.toLowerCase().contains(q)) ||
          gym.facilities.any((f) => f.label.toLowerCase().contains(q));
    }).toList();
  }

  static bool _matchesModalityFilter(Gym gym, String filter) {
    final f = filter.toLowerCase();
    if (f == '24h') {
      return gym.facilities.any((x) => x.label.toLowerCase().contains('24h')) ||
          gym.openHours.toLowerCase().contains('24');
    }
    final needle = f.toLowerCase();
    return gym.modalities.any((m) {
      final ml = m.toLowerCase();
      return ml.contains(needle) || needle.contains(ml);
    });
  }
}
