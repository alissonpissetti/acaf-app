/// Filtros da home (busca + critérios estruturados).
class AssociateSearchFilters {
  const AssociateSearchFilters({
    this.query = '',
    this.modalities = const {},
    this.minRating,
    this.structureKeys = const {},
    this.advantageKeys = const {},
  });

  final String query;
  final Set<String> modalities;
  /// Nota mínima (ex.: 4.5). Null = qualquer.
  final double? minRating;
  /// Chaves de [FacilityFilterCatalog.structureOptions].
  final Set<String> structureKeys;
  /// Chaves de [FacilityFilterCatalog.advantageOptions].
  final Set<String> advantageKeys;

  bool get isEmpty =>
      query.trim().isEmpty &&
      modalities.isEmpty &&
      minRating == null &&
      structureKeys.isEmpty &&
      advantageKeys.isEmpty;

  int get activeCount {
    var n = 0;
    if (query.trim().isNotEmpty) n++;
    if (modalities.isNotEmpty) n++;
    if (minRating != null) n++;
    if (structureKeys.isNotEmpty) n++;
    if (advantageKeys.isNotEmpty) n++;
    return n;
  }

  AssociateSearchFilters copyWith({
    String? query,
    Set<String>? modalities,
    double? minRating,
    bool clearMinRating = false,
    Set<String>? structureKeys,
    Set<String>? advantageKeys,
  }) {
    return AssociateSearchFilters(
      query: query ?? this.query,
      modalities: modalities ?? this.modalities,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      structureKeys: structureKeys ?? this.structureKeys,
      advantageKeys: advantageKeys ?? this.advantageKeys,
    );
  }

  static const empty = AssociateSearchFilters();
}
