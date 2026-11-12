/// Centros aproximados para centralizar o mapa quando o GPS não está disponível.
abstract final class CityMapCenters {
  static const defaultLat = -25.4284;
  static const defaultLng = -49.2733;

  static (double lat, double lng) forCity(String city) {
    switch (city) {
      case 'São Paulo':
        return (-23.5505, -46.6333);
      case 'Florianópolis':
        return (-27.5954, -48.548);
      case 'Joinville':
        return (-26.3045, -49.8482);
      case 'Curitiba':
      default:
        return (defaultLat, defaultLng);
    }
  }
}
