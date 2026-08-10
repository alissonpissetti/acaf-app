/// Áreas para explorar unidades (cidades retornadas pela API).
class SearchArea {
  const SearchArea({
    required this.id,
    required this.label,
    required this.cityMatch,
  });

  final String id;
  final String label;
  final String cityMatch;
}

List<SearchArea> searchAreasFromCities(List<String> cities) {
  return cities
      .map(
        (city) => SearchArea(
          id: city.toLowerCase().replaceAll(' ', '-'),
          label: city.contains('/') ? city : '$city, PR',
          cityMatch: city.split('/').first.trim(),
        ),
      )
      .toList();
}

SearchArea? searchAreaById(List<SearchArea> areas, String id) {
  for (final area in areas) {
    if (area.id == id) return area;
  }
  return null;
}
