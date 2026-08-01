import 'package:flutter/material.dart';

import '../models/gym.dart';

/// Atalhos para montar mocks de estrutura/vantagens.
abstract final class FacilityPresets {
  static const ac = GymFacility(label: 'Ar-condicionado', icon: Icons.ac_unit_rounded);
  static const hotShower = GymFacility(label: 'Chuveiro quente', icon: Icons.shower_rounded);
  static const lockers = GymFacility(label: 'Armários', icon: Icons.lock_rounded);
  static const parking = GymFacility(label: 'Estacionamento', icon: Icons.local_parking_rounded);
  static const wifi = GymFacility(label: 'Wi-Fi', icon: Icons.wifi_rounded);
  static const towel = GymFacility(label: 'Toalha inclusa', icon: Icons.dry_cleaning_rounded);
  static const water = GymFacility(label: 'Bebedouros', icon: Icons.water_drop_outlined);
  static const sauna = GymFacility(label: 'Sauna', icon: Icons.hot_tub_rounded);
  static const recovery = GymFacility(label: 'Área recovery', icon: Icons.spa_rounded);
  static const open24h = GymFacility(label: 'Aberto 24h', icon: Icons.schedule_rounded);
  static const accessibility = GymFacility(label: 'Acessibilidade', icon: Icons.accessible_rounded);
  static const cafe = GymFacility(label: 'Café / lanchonete', icon: Icons.local_cafe_rounded);
  static const kids = GymFacility(label: 'Espaço kids', icon: Icons.child_care_rounded);
  static const pool = GymFacility(label: 'Piscina', icon: Icons.pool_rounded);
  static const bikeRack = GymFacility(label: 'Bicicletário', icon: Icons.pedal_bike_rounded);
}
