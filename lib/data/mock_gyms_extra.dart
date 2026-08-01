import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../theme/app_colors.dart';
import 'facility_presets.dart';

/// Redes genéricas para unidades extras do mock (10 marcas × 3 unidades).
const extraMockNetworkIds = <({String id, String name, String tagline})>[
  (id: 'net_forge', name: 'Forge Fitness', tagline: 'Força e condicionamento'),
  (id: 'net_zenith', name: 'Zenith Gym', tagline: 'Treino inteligente'),
  (id: 'net_corpo_ativo', name: 'Corpo Ativo', tagline: 'Movimento todos os dias'),
  (id: 'net_pulse_norte', name: 'Pulse Norte', tagline: 'Rede associada ACAF'),
  (id: 'net_iron_lab', name: 'Iron Lab', tagline: 'Performance e hipertrofia'),
  (id: 'net_movimento', name: 'Movimento Club', tagline: 'Aulas e musculação'),
  (id: 'net_energia', name: 'Energia Total', tagline: 'Cardio e funcional'),
  (id: 'net_flex_curitiba', name: 'Flex Curitiba', tagline: 'Pilates e bem-estar'),
  (id: 'net_arena_curitiba', name: 'Arena Curitiba', tagline: 'Cross e box'),
  (id: 'net_vital', name: 'Vital Academias', tagline: 'Unidades pela cidade'),
];

const _neighborhoods = [
  'Boqueirão',
  'Cabral',
  'Cajuru',
  'CIC',
  'Fanny',
  'Guabirotuba',
  'Hauer',
  'Jardim Botânico',
  'Juvevê',
  'Linha Verde',
  'Mossunguê',
  'Novo Mundo',
  'Pinheirinho',
  'Rebouças',
  'São Braz',
  'Seminário',
  'Sítio Cercado',
  'Tingui',
  'Uberaba',
  'Vila Izabel',
  'Xaxim',
  'Alto da XV',
  'Campo Comprido',
  'Capão Raso',
  'Cidade Industrial',
  'Fazendinha',
  'Guaíra',
  'Parolin',
  'Prado Velho',
  'Tarumã',
];

const _modalitySets = [
  ['Musculação', 'Cardio'],
  ['Musculação', 'Funcional', 'HIIT'],
  ['Cross Training', 'Box', 'Funcional'],
  ['Yoga', 'Pilates', 'Alongamento'],
  ['Musculação', 'Natação', 'Hidroginástica'],
  ['Musculação', 'Personal trainer', 'Cardio'],
  ['Funcional', 'Aulas em grupo'],
  ['Musculação', 'LPO', 'Cross'],
];

const _facilitySets = [
  [FacilityPresets.ac, FacilityPresets.hotShower, FacilityPresets.lockers, FacilityPresets.wifi],
  [
    FacilityPresets.ac,
    FacilityPresets.hotShower,
    FacilityPresets.lockers,
    FacilityPresets.parking,
    FacilityPresets.wifi,
  ],
  [
    FacilityPresets.open24h,
    FacilityPresets.ac,
    FacilityPresets.hotShower,
    FacilityPresets.lockers,
    FacilityPresets.towel,
  ],
  [
    FacilityPresets.ac,
    FacilityPresets.hotShower,
    FacilityPresets.lockers,
    FacilityPresets.water,
    FacilityPresets.bikeRack,
  ],
];

const _heroIcons = [
  Icons.fitness_center_rounded,
  Icons.sports_gymnastics_rounded,
  Icons.directions_run_rounded,
  Icons.self_improvement_rounded,
  Icons.sports_martial_arts_rounded,
  Icons.pool_rounded,
];

/// 30 unidades extras em Curitiba (distâncias após o mock base).
List<Gym> buildExtraMockGyms() {
  const startDistance = 5.6;
  const distanceStep = 0.38;

  return List<Gym>.generate(30, (i) {
    final brand = extraMockNetworkIds[i % extraMockNetworkIds.length];
    final neighborhood = _neighborhoods[i % _neighborhoods.length];
    final modalities = _modalitySets[i % _modalitySets.length];
    final facilities = _facilitySets[i % _facilitySets.length];
    final rating = 4.2 + (i % 8) * 0.1;
    final daily = 32.9 + (i % 12) * 1.5;

    return Gym(
      id: 'g_extra_$i',
      networkId: brand.id,
      name: 'Unidade $neighborhood',
      neighborhood: neighborhood,
      city: 'Curitiba/PR',
      rating: double.parse(rating.toStringAsFixed(1)),
      distanceKm: double.parse((startDistance + i * distanceStep).toStringAsFixed(2)),
      modalities: modalities,
      facilities: facilities,
      openHours: i.isEven ? 'Seg–Sex 6h–22h · Sáb 8h–13h' : 'Seg–Sáb 5h30–23h',
      dailyPassPrice: double.parse(daily.toStringAsFixed(2)),
      heroTint: i.isEven ? AppColors.surfaceMuted : const Color(0xFFEFEFF1),
      heroIcon: _heroIcons[i % _heroIcons.length],
      plans: const [],
    );
  });
}
