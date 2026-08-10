import '../models/associate_search_filters.dart';
import '../models/gym.dart';
import '../models/gym_network.dart';
import '../state/catalog_state.dart';
import 'facility_filter_catalog.dart';

/// Fonte de associados da rede ACAF (acaf-api).
class AssociatesRepository {
  static const homePageSize = 10;

  AssociatesRepository(this._catalog);

  final CatalogState _catalog;

  GymNetwork? networkById(String id) => _catalog.repository.networkById(id);

  GymNetwork networkForUnit(Gym gym) => _catalog.repository.networkForUnit(gym);

  int networkUnitCount(String networkId) =>
      _catalog.repository.unitsForNetwork(networkId).length;

  Gym? gymById(String id) => _catalog.repository.gymById(id);

  List<Gym> nearbyAssociates() {
    final sorted = [..._catalog.repository.gyms]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return sorted;
  }

  static const _metroCuritibaCities = [
    'Curitiba',
    'São José dos Pinhais',
    'Pinhais',
    'Colombo',
    'Araucária',
  ];

  List<Gym> searchNearby({
    required String query,
    Set<String> modalityFilters = const {},
    String? cityFilter = 'Curitiba',
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
    String? cityFilter = 'Curitiba',
  }) {
    var list = nearbyAssociates();
    if (cityFilter != null && cityFilter.isNotEmpty) {
      list = list.where((g) => _matchesCityFilter(g, cityFilter)).toList();
    }

    if (filters.minRating != null) {
      list = list.where((g) => g.hasRating && g.rating >= filters.minRating!).toList();
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
      final network = networkForUnit(gym);
      return gym.name.toLowerCase().contains(q) ||
          network.name.toLowerCase().contains(q) ||
          gym.neighborhood.toLowerCase().contains(q) ||
          gym.modalities.any((m) => m.toLowerCase().contains(q)) ||
          gym.facilities.any((f) => f.label.toLowerCase().contains(q));
    }).toList();
  }

  static bool _matchesCityFilter(Gym gym, String cityFilter) {
    if (cityFilter == 'Curitiba') {
      return _metroCuritibaCities.any((city) => gym.city.contains(city));
    }
    return gym.city.contains(cityFilter);
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
