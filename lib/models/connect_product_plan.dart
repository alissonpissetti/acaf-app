class ConnectProductPlan {
  const ConnectProductPlan({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.description,
    required this.benefits,
    required this.highlight,
    this.tierIndex = 0,
  });

  final String id;
  final String name;
  final double pricePerMonth;
  final String description;
  final List<String> benefits;
  final bool highlight;
  final int tierIndex;

  /// Ex.: "Start", "Plus" (sem prefixo da marca).
  String get tierShortName => name.replaceFirst('Connect ', '');
}

/// Assinatura mensal Connect ativa (cartão cadastrado).
class ActiveConnectSubscription {
  ActiveConnectSubscription({
    required this.planId,
    required this.planName,
    required this.pricePerMonth,
    required this.since,
    required this.cardBrand,
    required this.cardLastFour,
  });

  final String planId;
  final String planName;
  final double pricePerMonth;
  final DateTime since;
  final String cardBrand;
  final String cardLastFour;
}

/// Plano escolhido em uma unidade associada (após fluxo de assinatura).
class ActiveGymSubscription {
  ActiveGymSubscription({
    required this.gymId,
    required this.gymName,
    required this.planId,
    required this.planName,
    required this.pricePerMonth,
    required this.since,
  });

  final String gymId;
  final String gymName;
  final String planId;
  final String planName;
  final double pricePerMonth;
  final DateTime since;
}
