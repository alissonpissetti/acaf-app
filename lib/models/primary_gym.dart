/// Academia principal do associado na plataforma (frequência mensal).
class PrimaryGymChoice {
  PrimaryGymChoice({
    required this.gymId,
    required this.gymName,
    required this.chosenAt,
    this.firstCheckInAt,
    this.checkInsSinceFirst = 0,
  });

  static const minCheckInsToChange = 12;

  final String gymId;
  final String gymName;
  final DateTime chosenAt;
  final DateTime? firstCheckInAt;
  final int checkInsSinceFirst;

  bool get hasStartedCheckIns => firstCheckInAt != null;

  bool get canChangeToAnotherGym {
    if (!hasStartedCheckIns) return true;
    return checkInsSinceFirst >= minCheckInsToChange;
  }

  int get remainingCheckInsBeforeChange {
    if (!hasStartedCheckIns) return 0;
    final left = minCheckInsToChange - checkInsSinceFirst;
    return left < 0 ? 0 : left;
  }

  PrimaryGymChoice copyWith({
    DateTime? firstCheckInAt,
    int? checkInsSinceFirst,
  }) {
    return PrimaryGymChoice(
      gymId: gymId,
      gymName: gymName,
      chosenAt: chosenAt,
      firstCheckInAt: firstCheckInAt ?? this.firstCheckInAt,
      checkInsSinceFirst: checkInsSinceFirst ?? this.checkInsSinceFirst,
    );
  }
}
