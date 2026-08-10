import '../data/connect_plans.dart';
import '../models/connect_product_plan.dart';
import '../services/acaf_api.dart';
import 'modality_catalog.dart';

/// Domínio ACAF Connect (planos e catálogo de modalidades) via acaf-api.
class ConnectDomain {
  ConnectDomain._({
    required this.schemaVersion,
    required this.acafDailyFeePercent,
    required this.connectPlans,
    required this.modalityCatalog,
  });

  final int schemaVersion;
  final double acafDailyFeePercent;
  final List<ConnectDomainPlan> connectPlans;
  final List<String> modalityCatalog;

  static ConnectDomain? _cache;

  static Future<ConnectDomain> load({AcafApi? api}) async {
    if (_cache != null) return _cache!;
    final client = api ?? AcafApi();
    final map = await client.fetchDomain();
    if (map == null) {
      throw StateError('Não foi possível carregar o domínio Connect da API.');
    }

    final domain = ConnectDomain._(
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      acafDailyFeePercent: (map['acafConnectFeePercent'] as num?)?.toDouble() ??
          (map['acafDailyFeePercent'] as num?)?.toDouble() ??
          20,
      connectPlans: (map['connectPlans'] as List<dynamic>)
          .map((e) => ConnectDomainPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      modalityCatalog: (map['modalityCatalog'] as List<dynamic>?)?.cast<String>() ?? const [],
    );

    _cache = domain;
    _syncConnectProductPlans(domain);
    setModalityCatalogOptions(domain.modalityCatalog);
    return domain;
  }

  static void _syncConnectProductPlans(ConnectDomain domain) {
    final highlightId = domain.connectPlans.length > 2 ? domain.connectPlans[2].id : null;
    setConnectProductPlans(
      domain.connectPlans
          .map(
            (plan) => ConnectProductPlan(
              id: plan.id,
              name: plan.name,
              pricePerMonth: plan.pricePerMonth,
              description: plan.description,
              tierIndex: plan.tierIndex,
              highlight: plan.id == highlightId,
              benefits: [
                'Rede completa de associados ACAF Connect',
                'Check-in pelo app · 1 visita/dia',
                if (plan.tierIndex >= 2) 'Suporte prioritário ACAF Connect',
              ],
            ),
          )
          .toList(),
    );
  }

  ConnectDomainPlan? planById(String id) {
    for (final p in connectPlans) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class ConnectDomainPlan {
  const ConnectDomainPlan({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.tierIndex,
    required this.description,
  });

  final String id;
  final String name;
  final double pricePerMonth;
  final int tierIndex;
  final String description;

  factory ConnectDomainPlan.fromJson(Map<String, dynamic> json) {
    return ConnectDomainPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      pricePerMonth: (json['pricePerMonth'] as num).toDouble(),
      tierIndex: json['tierIndex'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}
