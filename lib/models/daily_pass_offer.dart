/// Oferta de diária disponível para compra no dia (integral ou faixa promocional).
class DailyPassOffer {
  const DailyPassOffer({
    required this.id,
    required this.kind,
    required this.label,
    required this.modalities,
    required this.price,
    this.startTime,
    this.endTime,
    this.pricingRuleId,
  });

  final String id;
  final DailyPassOfferKind kind;
  final String label;
  final List<String> modalities;
  final double price;
  final String? startTime;
  final String? endTime;
  final String? pricingRuleId;

  bool get isFullDay => kind == DailyPassOfferKind.fullDay;

  String get validityLabel {
    if (isFullDay) return 'Válida até 23:59 de hoje nesta unidade.';
    if (startTime != null && endTime != null) {
      return 'Válida hoje das ${formatDailyPassTime(startTime!)} às ${formatDailyPassTime(endTime!)}.';
    }
    return 'Válida hoje nesta unidade.';
  }

  String get modalitiesSummary {
    if (modalities.isEmpty) return 'Consulte a recepção';
    return modalities.join(', ');
  }

  String get windowLabel {
    if (isFullDay) return 'Dia inteiro';
    if (startTime != null && endTime != null) {
      return '${formatDailyPassTime(startTime!)}–${formatDailyPassTime(endTime!)}';
    }
    return 'Hoje';
  }

  factory DailyPassOffer.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String? ?? 'full_day';
    return DailyPassOffer(
      id: json['id'] as String,
      kind: kindRaw == 'window' ? DailyPassOfferKind.window : DailyPassOfferKind.fullDay,
      label: json['label'] as String? ?? 'Diária',
      modalities: (json['modalities'] as List<dynamic>?)?.cast<String>() ?? const [],
      price: (json['price'] as num).toDouble(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      pricingRuleId: json['pricingRuleId'] as String?,
    );
  }

  /// Constrói oferta integral a partir de dados da unidade (catálogo).
  factory DailyPassOffer.integralFromGym({
    required String id,
    required double price,
    required List<String> modalities,
  }) {
    return DailyPassOffer(
      id: id,
      kind: DailyPassOfferKind.fullDay,
      label: 'Diária integral',
      modalities: modalities,
      price: price,
      pricingRuleId: null,
    );
  }
}

enum DailyPassOfferKind { fullDay, window }

String formatDailyPassTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1];
  return m == '00' ? '${h}h' : '${h}h$m';
}

class DailyPassOffersResponse {
  const DailyPassOffersResponse({
    required this.unitId,
    required this.date,
    required this.offers,
  });

  final String unitId;
  final String date;
  final List<DailyPassOffer> offers;

  factory DailyPassOffersResponse.fromJson(Map<String, dynamic> json) {
    final rows = json['offers'] as List<dynamic>? ?? const [];
    return DailyPassOffersResponse(
      unitId: json['unitId'] as String,
      date: json['date'] as String,
      offers: rows
          .map((item) => DailyPassOffer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
