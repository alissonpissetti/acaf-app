import 'package:flutter/material.dart';

class GymFacility {
  const GymFacility({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.description,
    required this.benefits,
    this.connectPlanId,
    this.includedModalities = const [],
  });

  final String id;
  final String name;
  final double pricePerMonth;
  final String description;
  final List<String> benefits;

  /// Mesmo tier do plano ACAF Connect (`connect-start`, `connect-plus`, …).
  final String? connectPlanId;

  /// Modalidades liberadas neste plano (configuração da unidade no painel da academia).
  final List<String> includedModalities;

  String get modalitiesLabel {
    if (includedModalities.isEmpty) {
      return 'Modalidades definidas pela unidade';
    }
    if (includedModalities.length == 1) {
      return includedModalities.first;
    }
    return includedModalities.join(', ');
  }
}

class Gym {
  const Gym({
    required this.id,
    required this.networkId,
    required this.name,
    required this.neighborhood,
    required this.city,
    required this.rating,
    required this.distanceKm,
    required this.modalities,
    required this.facilities,
    required this.openHours,
    required this.dailyPassPrice,
    required this.plans,
    required this.heroTint,
    required this.heroIcon,
    this.dailyPassModalities = const [],
    this.heroImageAsset,
    this.brandLogoAsset,
    this.brandLogoWidthFactor = 1,
    this.galleryImageAssets = const [],
  });

  final String id;
  final String networkId;
  final String name;
  final String neighborhood;
  final String city;
  final double rating;
  final double distanceKm;
  /// Modalidades oferecidas na unidade (musculação, yoga, cross, etc.).
  final List<String> modalities;
  /// Estrutura e vantagens do local.
  final List<GymFacility> facilities;
  final String openHours;
  final double dailyPassPrice;
  /// Modalidades liberadas na diária (painel academia). Vazio = todas [modalities].
  final List<String> dailyPassModalities;
  final List<SubscriptionPlan> plans;
  final Color heroTint;
  final IconData heroIcon;
  /// Foto da unidade (card e detalhe).
  final String? heroImageAsset;
  /// Marca da academia associada.
  final String? brandLogoAsset;
  /// Largura relativa do logo no hero (1 = quadrado; ~2,2 para lockups horizontais).
  final double brandLogoWidthFactor;
  /// Fotos adicionais (detalhe / carrossel).
  final List<String> galleryImageAssets;

  List<String> get photoAssets {
    if (galleryImageAssets.isNotEmpty) return galleryImageAssets;
    if (heroImageAsset != null) return [heroImageAsset!];
    return const [];
  }

  String get locationLabel => '$neighborhood · $city';

  /// Modalidades que o visitante vê na compra de diária.
  List<String> get dailyPassIncludedModalities {
    if (dailyPassModalities.isEmpty) return modalities;
    return dailyPassModalities
        .where((m) => modalities.any((u) => u.toLowerCase() == m.toLowerCase()))
        .toList();
  }

  /// Modalidades da unidade que **não** entram na diária (para transparência na compra).
  List<String> get dailyPassExcludedModalities {
    final included = dailyPassIncludedModalities.map((m) => m.toLowerCase()).toSet();
    return modalities.where((m) => !included.contains(m.toLowerCase())).toList();
  }

  String get dailyPassModalitiesSummary {
    final list = dailyPassIncludedModalities;
    if (list.isEmpty) return 'Consulte a recepção';
    return list.join(', ');
  }

  /// Rótulo da unidade no card (bairro ou nome curto).
  String get unitLabel => name.contains('·') ? name.split('·').last.trim() : neighborhood;

  Gym copyWith({
    List<SubscriptionPlan>? plans,
    List<String>? dailyPassModalities,
  }) {
    return Gym(
      id: id,
      networkId: networkId,
      name: name,
      neighborhood: neighborhood,
      city: city,
      rating: rating,
      distanceKm: distanceKm,
      modalities: modalities,
      facilities: facilities,
      openHours: openHours,
      dailyPassPrice: dailyPassPrice,
      dailyPassModalities: dailyPassModalities ?? this.dailyPassModalities,
      plans: plans ?? this.plans,
      heroTint: heroTint,
      heroIcon: heroIcon,
      heroImageAsset: heroImageAsset,
      brandLogoAsset: brandLogoAsset,
      brandLogoWidthFactor: brandLogoWidthFactor,
      galleryImageAssets: galleryImageAssets,
    );
  }
}

enum PurchaseType { subscription, dailyPass }

class WalletItem {
  WalletItem({
    required this.id,
    required this.gym,
    required this.type,
    required this.title,
    required this.purchasedAt,
    this.planName,
    this.validUntil,
    this.checkInCode,
  });

  final String id;
  final Gym gym;
  final PurchaseType type;
  final String title;
  final DateTime purchasedAt;
  final String? planName;
  final DateTime? validUntil;
  final String? checkInCode;

  bool get isActiveDailyPass {
    if (type != PurchaseType.dailyPass) return false;
    final until = validUntil;
    if (until == null) return true;
    return !DateTime.now().isAfter(until);
  }
}
