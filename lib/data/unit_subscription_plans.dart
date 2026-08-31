import '../models/connect_product_plan.dart';
import '../models/gym.dart';
import 'connect_plans.dart' as connect_plans;
import 'daily_pass_modalities.dart';

/// Oferta de um tier Connect na unidade (dados da API).
class UnitPlanSpec {
  const UnitPlanSpec({
    required this.connectPlanId,
    this.includedModalities = const [],
    this.exactOnly = false,
  });

  final String connectPlanId;

  /// Modalidades explícitas (ex.: só Musculação no Plus).
  final List<String> includedModalities;

  /// Se true, o plano fica **apenas** com [includedModalities] (tiers inferiores).
  /// Planos mais caros sem [exactOnly] ampliam a lista com outras modalidades da unidade.
  final bool exactOnly;
}

List<UnitPlanSpec> defaultUnitPlanSpecs(List<String> unitModalities) {
  if (unitModalities.length <= 1) {
    return const [UnitPlanSpec(connectPlanId: 'connect-start')];
  }
  if (unitModalities.length == 2) {
    return const [
      UnitPlanSpec(connectPlanId: 'connect-start'),
      UnitPlanSpec(connectPlanId: 'connect-plus'),
    ];
  }
  if (unitModalities.length <= 4) {
    return const [
      UnitPlanSpec(connectPlanId: 'connect-start'),
      UnitPlanSpec(connectPlanId: 'connect-plus'),
      UnitPlanSpec(connectPlanId: 'connect-multi'),
      UnitPlanSpec(connectPlanId: 'connect-pro'),
    ];
  }
  return const [
    UnitPlanSpec(connectPlanId: 'connect-start'),
    UnitPlanSpec(connectPlanId: 'connect-plus'),
    UnitPlanSpec(connectPlanId: 'connect-multi'),
    UnitPlanSpec(connectPlanId: 'connect-pro'),
    UnitPlanSpec(connectPlanId: 'connect-total'),
  ];
}

List<UnitPlanSpec> unitPlanSpecsForGym(Gym gym) {
  if (gym.planSpecs.isNotEmpty) return gym.planSpecs;
  return defaultUnitPlanSpecs(gym.modalities);
}

List<SubscriptionPlan> buildUnitConnectPlans({required Gym gym}) {
  final specs = unitPlanSpecsForGym(gym);
  final unitModalities = gym.modalities;
  final gymId = gym.id;
  final plans = <SubscriptionPlan>[];
  var baselineModalities = <String>[];

  for (final spec in specs) {
    final connect = connect_plans.connectPlanById(spec.connectPlanId);
    if (connect == null) continue;

    final scoped = _resolveModalities(
      spec: spec,
      connect: connect,
      unitModalities: unitModalities,
      baselineModalities: baselineModalities,
    );

    baselineModalities = _mergeModalities(baselineModalities, scoped);

    plans.add(
      SubscriptionPlan(
        id: 'unit_${gymId}_${connect.id}',
        name: connect.name,
        pricePerMonth: connect.pricePerMonth,
        connectPlanId: connect.id,
        includedModalities: scoped,
        description: _descriptionFor(connect, scoped, unitModalities, spec),
        benefits: _benefitsFor(connect, scoped, unitModalities),
      ),
    );
  }

  plans.sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
  return plans;
}

List<String> _mergeModalities(List<String> baseline, List<String> scoped) {
  final out = [...baseline];
  for (final m in scoped) {
    if (!out.any((x) => x.toLowerCase() == m.toLowerCase())) {
      out.add(m);
    }
  }
  return out;
}

List<String> _filterToUnit(List<String> names, List<String> unitModalities) {
  return names
      .where((m) => unitModalities.any((u) => u.toLowerCase() == m.toLowerCase()))
      .toList();
}

List<String> _expandModalities({
  required List<String> unitModalities,
  required int? limit,
  required List<String> mustInclude,
}) {
  final maxCount = limit == null
      ? unitModalities.length
      : limit.clamp(0, unitModalities.length);

  final picked = <String>[];

  for (final m in mustInclude) {
    if (picked.length >= maxCount) break;
    final match = unitModalities.where((u) => u.toLowerCase() == m.toLowerCase()).firstOrNull;
    if (match != null && !picked.any((p) => p.toLowerCase() == match.toLowerCase())) {
      picked.add(match);
    }
  }

  for (final m in unitModalities) {
    if (picked.length >= maxCount) break;
    if (!picked.any((p) => p.toLowerCase() == m.toLowerCase())) {
      picked.add(m);
    }
  }

  return picked;
}

List<String> _resolveModalities({
  required UnitPlanSpec spec,
  required ConnectProductPlan connect,
  required List<String> unitModalities,
  required List<String> baselineModalities,
}) {
  if (spec.includedModalities.isNotEmpty && spec.exactOnly) {
    return _filterToUnit(spec.includedModalities, unitModalities);
  }

  if (spec.includedModalities.isNotEmpty) {
    return _filterToUnit(spec.includedModalities, unitModalities);
  }

  final limit = _modalityCapForTier(connect.id, unitModalities.length);
  return _expandModalities(
    unitModalities: unitModalities,
    limit: limit,
    mustInclude: baselineModalities,
  );
}

/// Quando a unidade não lista modalidades no spec, amplia progressivamente por tier Connect.
int? _modalityCapForTier(String connectPlanId, int unitCount) {
  if (connectPlanId == 'connect-total') return null;
  final idx = connectPlanTierIndex(connectPlanId);
  if (idx < 0) return unitCount;
  return (idx + 1).clamp(1, unitCount);
}

String _descriptionFor(
  ConnectProductPlan connect,
  List<String> scoped,
  List<String> unitModalities,
  UnitPlanSpec spec,
) {
  if (scoped.isEmpty) {
    return 'Oferta ${connect.tierShortName} configurada nesta unidade.';
  }
  return scoped.join(', ');
}

List<String> _benefitsFor(
  ConnectProductPlan connect,
  List<String> scoped,
  List<String> unitModalities,
) {
  return <String>[
    if (scoped.isNotEmpty) 'Modalidades: ${scoped.join(', ')}',
    '1 check-in/dia nesta unidade',
    'Tier ${connect.tierShortName} · Connect',
  ];
}

Gym applyConnectPlansToGym(Gym gym) {
  return applyDailyPassModalitiesToGym(
    gym.copyWith(
      plans: buildUnitConnectPlans(gym: gym),
    ),
  );
}

List<Gym> applyConnectPlansToAll(List<Gym> gyms) {
  return gyms.map(applyConnectPlansToGym).toList();
}

double unitPlansFromPrice(List<SubscriptionPlan> plans) {
  if (plans.isEmpty) return 39.90;
  return plans.map((p) => p.pricePerMonth).reduce((a, b) => a < b ? a : b);
}

/// Índice do tier Connect (0 = Start … 4 = Total).
int connectPlanTierIndex(String connectPlanId) {
  return connect_plans.connectPlanTierIndex(connectPlanId);
}

/// Planos da unidade que o associado pode **contratar** (tier Connect dele ou mais barato).
List<SubscriptionPlan> eligibleUnitPlansForConnect(
  List<SubscriptionPlan> unitPlans,
  String? userConnectPlanId,
) {
  if (userConnectPlanId == null || unitPlans.isEmpty) return const [];

  final userIdx = connectPlanTierIndex(userConnectPlanId);
  if (userIdx < 0) {
    final userPlan = connect_plans.connectPlanById(userConnectPlanId);
    final cap = userPlan?.pricePerMonth ?? double.infinity;
    return unitPlans.where((p) => p.pricePerMonth <= cap).toList()
      ..sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
  }

  final eligible = unitPlans.where((plan) {
    final tierId = plan.connectPlanId;
    if (tierId == null) {
      return plan.pricePerMonth <= connect_plans.connectProductPlans[userIdx].pricePerMonth;
    }
    final tierIdx = connectPlanTierIndex(tierId);
    return tierIdx >= 0 && tierIdx <= userIdx;
  }).toList();

  eligible.sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
  return eligible;
}

List<SubscriptionPlan> sortedUnitPlans(List<SubscriptionPlan> unitPlans) {
  final out = [...unitPlans]..sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
  return out;
}

bool isUnitPlanSubscribable(SubscriptionPlan plan, String userConnectPlanId) {
  return eligibleUnitPlansForConnect([plan], userConnectPlanId).isNotEmpty;
}

/// Tier do plano na unidade acima do Connect atual (só vitrine / upgrade).
bool isUnitPlanAboveUserConnectTier(SubscriptionPlan plan, String userConnectPlanId) {
  if (!isUnitPlanSubscribable(plan, userConnectPlanId)) {
    final userIdx = connectPlanTierIndex(userConnectPlanId);
    if (userIdx < 0) {
      final userPlan = connect_plans.connectPlanById(userConnectPlanId);
      if (userPlan == null) return false;
      return plan.pricePerMonth > userPlan.pricePerMonth;
    }
    final tierId = plan.connectPlanId;
    if (tierId == null) {
      return plan.pricePerMonth > connect_plans.connectProductPlans[userIdx].pricePerMonth;
    }
    final planIdx = connectPlanTierIndex(tierId);
    return planIdx >= 0 && planIdx > userIdx;
  }
  return false;
}

ConnectProductPlan? connectPlanForSubscription(ActiveConnectSubscription? sub) {
  if (sub == null) return null;
  return connect_plans.connectPlanById(sub.planId);
}
