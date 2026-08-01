import '../models/connect_product_plan.dart';

/// Planos mensais ACAF Connect (Start → Total).
/// Quais modalidades entram em cada tier é definido no painel de cada academia.
const List<ConnectProductPlan> connectProductPlans = [
  ConnectProductPlan(
    id: 'connect-start',
    name: 'ACAF Start',
    pricePerMonth: 39.90,
    description: 'Plano de entrada na rede ACAF Connect.',
    highlight: false,
    benefits: [
      'Rede completa de associados ACAF Connect',
      'Check-in pelo app · 1 visita/dia',
      'Modalidades conforme cada unidade visitada',
    ],
  ),
  ConnectProductPlan(
    id: 'connect-plus',
    name: 'ACAF Plus',
    pricePerMonth: 69.90,
    description: 'Mais flexibilidade dentro da rede.',
    highlight: false,
    benefits: [
      'Rede completa de associados ACAF Connect',
      'Check-in pelo app · 1 visita/dia',
      'Modalidades conforme cada unidade visitada',
    ],
  ),
  ConnectProductPlan(
    id: 'connect-multi',
    name: 'ACAF Multi',
    pricePerMonth: 129.90,
    description: 'Para quem treina com frequência em várias unidades.',
    highlight: true,
    benefits: [
      'Rede completa de associados ACAF Connect',
      'Check-in pelo app · 1 visita/dia',
      'Suporte prioritário ACAF Connect',
    ],
  ),
  ConnectProductPlan(
    id: 'connect-pro',
    name: 'ACAF Pro',
    pricePerMonth: 189.90,
    description: 'Tier avançado para uso intenso da rede.',
    highlight: false,
    benefits: [
      'Rede completa de associados ACAF Connect',
      'Check-in pelo app · 1 visita/dia',
      'Suporte prioritário ACAF Connect',
    ],
  ),
  ConnectProductPlan(
    id: 'connect-total',
    name: 'ACAF Total',
    pricePerMonth: 299.90,
    description: 'Máximo nível de benefícios ACAF Connect.',
    highlight: false,
    benefits: [
      'Rede completa de associados ACAF Connect',
      'Check-in pelo app · 1 visita/dia',
      'Suporte prioritário ACAF Connect',
    ],
  ),
];

ConnectProductPlan? connectPlanById(String id) {
  for (final plan in connectProductPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}
