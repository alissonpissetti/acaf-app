class ModalityAvailabilitySlot {
  ModalityAvailabilitySlot({
    required this.occurrenceKey,
    required this.occurrenceDate,
    this.slotTemplateId,
    this.overrideId,
    required this.modality,
    this.instructorName,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.booked,
    required this.available,
  });

  final String occurrenceKey;
  final String occurrenceDate;
  final String? slotTemplateId;
  final String? overrideId;
  final String modality;
  final String? instructorName;
  final String startTime;
  final String endTime;
  final int capacity;
  final int booked;
  final int available;

  factory ModalityAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return ModalityAvailabilitySlot(
      occurrenceKey: json['occurrenceKey'] as String? ?? '',
      occurrenceDate: json['occurrenceDate'] as String? ?? '',
      slotTemplateId: json['slotTemplateId'] as String?,
      overrideId: json['overrideId'] as String?,
      modality: json['modality'] as String? ?? '',
      instructorName: json['instructorName'] as String?,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      booked: (json['booked'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
    );
  }

  double get fillRatio => capacity > 0 ? booked / capacity : 0;

  bool get isFull => available <= 0;

  String get occupancyLabel {
    if (capacity <= 0) return 'Capacidade não definida';
    final freeLabel = available == 1 ? '1 livre' : '$available livres';
    return '$booked/$capacity · $freeLabel';
  }

  String get instructorLabel =>
      instructorName != null && instructorName!.trim().isNotEmpty
          ? 'Prof. ${instructorName!.trim()}'
          : 'Professor não informado';

  String get reservationsSummary {
    if (booked == 0) return 'Sem reservas';
    return booked == 1 ? '1 confirmada' : '$booked confirmadas';
  }
}

class ModalityReservation {
  ModalityReservation({
    required this.id,
    required this.unitId,
    required this.occurrenceDate,
    this.slotTemplateId,
    this.overrideId,
    required this.modality,
    this.instructorName,
    required this.startTime,
    required this.endTime,
    required this.holderName,
    required this.status,
    required this.reservedAt,
  });

  final String id;
  final String unitId;
  final String occurrenceDate;
  final String? slotTemplateId;
  final String? overrideId;
  final String modality;
  final String? instructorName;
  final String startTime;
  final String endTime;
  final String holderName;
  final String status;
  final String reservedAt;

  bool get isActive => status == 'confirmed' || status == 'checked_in';

  String get statusLabel {
    switch (status) {
      case 'checked_in':
        return 'Check-in feito';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Confirmada';
    }
  }

  factory ModalityReservation.fromJson(Map<String, dynamic> json) {
    return ModalityReservation(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      occurrenceDate: json['occurrenceDate'] as String,
      slotTemplateId: json['slotTemplateId'] as String?,
      overrideId: json['overrideId'] as String?,
      modality: json['modality'] as String,
      instructorName: json['instructorName'] as String?,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      holderName: json['holderName'] as String,
      status: json['status'] as String? ?? 'confirmed',
      reservedAt: json['reservedAt'] as String,
    );
  }
}
