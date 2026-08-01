class SavedPaymentCard {
  SavedPaymentCard({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.holderName,
    required this.expiryLabel,
    required this.addedAt,
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String lastFour;
  final String holderName;
  final String expiryLabel;
  final DateTime addedAt;
  final bool isDefault;

  String get maskedNumber => '•••• •••• •••• $lastFour';
}

enum BillingEntryStatus { paid, pending, failed }

enum BillingEntryKind { connectSubscription, gymSubscription, dailyPass }

class BillingEntry {
  BillingEntry({
    required this.id,
    required this.occurredAt,
    required this.description,
    required this.amount,
    required this.kind,
    required this.status,
    this.cardLastFour,
  });

  final String id;
  final DateTime occurredAt;
  final String description;
  final double amount;
  final BillingEntryKind kind;
  final BillingEntryStatus status;
  final String? cardLastFour;
}
