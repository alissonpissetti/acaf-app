import '../models/gym.dart';
import '../state/app_state.dart';

enum ModalityBookingAccessKind {
  dailyPass,
  planMembership,
  denied,
}

class ModalityBookingAccess {
  const ModalityBookingAccess({
    required this.kind,
    this.reason,
    this.accessLabel,
  });

  final ModalityBookingAccessKind kind;
  final String? reason;
  final String? accessLabel;

  bool get canBook => kind != ModalityBookingAccessKind.denied;
}

String _formatDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool _modalityMatches(String modality, String candidate) {
  return modality.toLowerCase() == candidate.toLowerCase();
}

bool _listIncludesModality(List<String> modalities, String modality) {
  return modalities.any((m) => _modalityMatches(m, modality));
}

bool _planIncludesModality(SubscriptionPlan plan, Gym gym, String modality) {
  if (plan.includedModalities.isNotEmpty) {
    return _listIncludesModality(plan.includedModalities, modality);
  }
  return _listIncludesModality(gym.modalities, modality);
}

bool _dailyPassIncludesModality(WalletItem pass, Gym gym, String modality) {
  if (pass.allowedModalities.isNotEmpty) {
    return _listIncludesModality(pass.allowedModalities, modality);
  }
  return _listIncludesModality(gym.dailyPassIncludedModalities, modality);
}

bool _dailyPassValidForDate(WalletItem pass, String occurrenceDate) {
  if (!pass.isActiveDailyPass) return false;
  return occurrenceDate == _formatDateKey(DateTime.now());
}

SubscriptionPlan? _planById(Gym gym, String planId) {
  for (final plan in gym.plans) {
    if (plan.id == planId) return plan;
  }
  return null;
}

SubscriptionPlan? _planByConnectId(Gym gym, String connectPlanId) {
  for (final plan in gym.plans) {
    if (plan.connectPlanId == connectPlanId) return plan;
  }
  return null;
}

/// Avalia se o associado pode reservar a modalidade nesta unidade.
ModalityBookingAccess evaluateModalityBookingAccess({
  required AppState appState,
  required Gym gym,
  required String modality,
  String? occurrenceDate,
}) {
  final dateKey = occurrenceDate ?? _formatDateKey(DateTime.now());

  final daily = appState.activeDailyPassForGym(gym.id);
  if (daily != null) {
    if (!_dailyPassValidForDate(daily, dateKey)) {
      return ModalityBookingAccess(
        kind: ModalityBookingAccessKind.denied,
        reason:
            'A diária vale só para o dia de hoje. Para reservar em outra data, use seu plano nesta unidade.',
      );
    }
    if (!_dailyPassIncludesModality(daily, gym, modality)) {
      final covered = daily.allowedModalities.isNotEmpty
          ? daily.allowedModalities.join(', ')
          : gym.dailyPassModalitiesSummary;
      return ModalityBookingAccess(
        kind: ModalityBookingAccessKind.denied,
        reason: 'Sua diária não inclui $modality. Modalidades: $covered.',
      );
    }
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.dailyPass,
      accessLabel: 'Diária ativa nesta unidade',
    );
  }

  final gymSub = appState.activeGymSubscription;
  if (gymSub != null && gymSub.gymId == gym.id) {
    final plan = _planById(gym, gymSub.planId);
    if (plan != null && _planIncludesModality(plan, gym, modality)) {
      return ModalityBookingAccess(
        kind: ModalityBookingAccessKind.planMembership,
        accessLabel: 'Plano ${gymSub.planName} nesta unidade',
      );
    }
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.denied,
      reason:
          'Seu plano ${gymSub.planName} nesta unidade não inclui $modality. '
          'Contrate um tier superior ou compre uma diária.',
    );
  }

  final connect = appState.activeConnectSubscription;
  final primary = appState.primaryGym;
  if (connect != null && primary != null && primary.gymId == gym.id) {
    final plan = _planByConnectId(gym, connect.planId);
    if (plan != null && _planIncludesModality(plan, gym, modality)) {
      return ModalityBookingAccess(
        kind: ModalityBookingAccessKind.planMembership,
        accessLabel: '${connect.planName} · academia principal',
      );
    }
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.denied,
      reason:
          'Seu ${connect.planName} nesta unidade não inclui $modality. '
          'Faça upgrade do plano ou compre uma diária.',
    );
  }

  if (connect == null) {
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.denied,
      reason:
          'Para reservar aulas, compre uma diária nesta unidade ou ative um plano ACAF Connect em Minha conta.',
    );
  }

  if (primary == null) {
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.denied,
      reason:
          'Escolha esta unidade como sua academia principal, ou compre uma diária válida para hoje.',
    );
  }

  if (primary.gymId != gym.id) {
    return ModalityBookingAccess(
      kind: ModalityBookingAccessKind.denied,
      reason:
          'Reservas com plano só na sua academia principal (${primary.gymName}). '
          'Para usar esta unidade, compre uma diária válida para hoje.',
    );
  }

  return ModalityBookingAccess(
    kind: ModalityBookingAccessKind.denied,
    reason: 'Não foi possível validar seu acesso para reservar nesta unidade.',
  );
}
