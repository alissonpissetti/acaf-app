import 'package:flutter/foundation.dart';

import '../data/catalog_repository.dart';

/// Estado global do catálogo de academias (fonte: connect-api).
class CatalogState extends ChangeNotifier {
  CatalogState({CatalogRepository? repository}) : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  bool get isReady => _repository.isLoaded && _error == null;

  CatalogRepository get repository => _repository;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.reload();
      _error = null;
    } catch (e) {
      _error = e is StateError ? e.message : 'Não foi possível carregar academias.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
