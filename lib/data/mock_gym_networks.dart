import '../branding/gym_brand_assets.dart';
import '../models/gym_network.dart';
import 'mock_gyms_extra.dart';

const List<GymNetwork> _coreMockGymNetworks = [
  GymNetwork(
    id: 'net_carpe',
    name: 'Carpe Diem Academia',
    tagline: 'Rede associada ACAF · Curitiba',
    brandLogoAsset: GymBrandAssets.carpeDiemLogo,
  ),
  GymNetwork(
    id: 'net_viver',
    name: 'Academia Viver Sports',
    tagline: 'Musculação, cardio e piscina',
    brandLogoAsset: GymBrandAssets.viverSportsLogo,
  ),
  GymNetwork(
    id: 'net_equilibrium',
    name: 'Equilibrium Fitness',
    tagline: 'Treino e equilíbrio',
    brandLogoAsset: GymBrandAssets.equilibriumLogo,
    brandLogoWidthFactor: 2.3,
  ),
  GymNetwork(
    id: 'net_wolf',
    name: 'WOLF Fitness',
    tagline: 'Força e performance',
    brandLogoAsset: GymBrandAssets.wolfFitnessLogo,
    brandLogoWidthFactor: 0.95,
  ),
  GymNetwork(
    id: 'net_pulse',
    name: 'Pulse Academias',
    tagline: 'Unidades em toda a região',
  ),
  GymNetwork(
    id: 'net_viver_sp',
    name: 'Academia Viver Sports',
    tagline: 'Unidades em São Paulo',
    brandLogoAsset: GymBrandAssets.viverSportsLogo,
  ),
];

final List<GymNetwork> mockGymNetworks = [
  ..._coreMockGymNetworks,
  ...extraMockGymNetworks,
];

/// Redes das 30 unidades extras ([buildExtraMockGyms]).
final List<GymNetwork> extraMockGymNetworks = extraMockNetworkIds
    .map(
      (b) => GymNetwork(
        id: b.id,
        name: b.name,
        tagline: b.tagline,
      ),
    )
    .toList();

GymNetwork? gymNetworkById(String id) {
  for (final network in mockGymNetworks) {
    if (network.id == id) return network;
  }
  return null;
}
