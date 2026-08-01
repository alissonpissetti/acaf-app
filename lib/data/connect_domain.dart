import 'dart:convert';

import 'package:flutter/services.dart';

/// Domínio ACAF Connect espelhado de `acaf_gym/shared/connect_domain.json`.
/// Atualize com `npm run sync:shared` no projeto acaf_gym.
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

  static const assetPath = 'assets/shared/connect_domain.json';
  static ConnectDomain? _cache;

  static Future<ConnectDomain> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _cache = ConnectDomain._(
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      acafDailyFeePercent: (map['acafConnectFeePercent'] as num?)?.toDouble() ??
          (map['acafDailyFeePercent'] as num?)?.toDouble() ??
          20,
      connectPlans: (map['connectPlans'] as List<dynamic>)
          .map((e) => ConnectDomainPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      modalityCatalog: (map['modalityCatalog'] as List<dynamic>).cast<String>(),
    );
    return _cache!;
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
      tierIndex: json['tierIndex'] as int,
      description: json['description'] as String? ?? '',
    );
  }
}
