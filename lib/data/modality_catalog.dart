import '../data/connect_domain.dart';

List<String> _catalogOptions = [];

void setModalityCatalogOptions(List<String> options) {
  _catalogOptions = List.of(options);
}

/// Modalidades do domínio Movly + unidades já carregadas.
List<String> allModalityOptions() {
  final options = <String>{..._catalogOptions};
  final sorted = options.where((o) => o != '24h').toList()
    ..sort((a, b) => a.compareTo(b));
  return ['24h', ...sorted];
}

Future<void> ensureModalityCatalogLoaded() async {
  if (_catalogOptions.isNotEmpty) return;
  final domain = await ConnectDomain.load();
  setModalityCatalogOptions(domain.modalityCatalog);
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
