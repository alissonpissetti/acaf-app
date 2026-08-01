/// Áreas disponíveis para explorar unidades (mock — substituir por API).
class SearchArea {
  const SearchArea({
    required this.id,
    required this.label,
    required this.cityMatch,
  });

  final String id;
  final String label;
  /// Filtro em [Gym.city] (contém este texto).
  final String cityMatch;
}

const List<SearchArea> mockSearchAreas = [
  SearchArea(id: 'curitiba', label: 'Curitiba, PR', cityMatch: 'Curitiba'),
  SearchArea(id: 'sao_paulo', label: 'São Paulo, SP', cityMatch: 'São Paulo'),
  SearchArea(id: 'florianopolis', label: 'Florianópolis, SC', cityMatch: 'Florianópolis'),
  SearchArea(id: 'joinville', label: 'Joinville, SC', cityMatch: 'Joinville'),
];

SearchArea? searchAreaById(String id) {
  for (final area in mockSearchAreas) {
    if (area.id == id) return area;
  }
  return null;
}
