import '../models/connect_product_plan.dart';

List<ConnectProductPlan> _connectProductPlans = [];

List<ConnectProductPlan> get connectProductPlans => List.unmodifiable(_connectProductPlans);

void setConnectProductPlans(List<ConnectProductPlan> plans) {
  _connectProductPlans = List.of(plans);
}

ConnectProductPlan? connectPlanById(String id) {
  for (final plan in _connectProductPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}

int connectPlanTierIndex(String id) {
  final plan = connectPlanById(id);
  if (plan == null) return -1;
  return plan.tierIndex;
}
