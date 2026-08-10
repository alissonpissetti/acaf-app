import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class CheckInLocationService {
  static const double maxRadiusKm = 1;

  Future<Position> resolvePosition({double? gymLatitude, double? gymLongitude}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const CheckInLocationException('Ative o GPS do celular para fazer check-in.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const CheckInLocationException('Permissão de localização necessária para check-in.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const CheckInLocationException(
          'Permissão de localização bloqueada. Libere nas configurações do celular.',
        );
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      if (kDebugMode && gymLatitude != null && gymLongitude != null) {
        return Position(
          latitude: gymLatitude,
          longitude: gymLongitude,
          timestamp: DateTime.now(),
          accuracy: 8,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      if (e is CheckInLocationException) throw e;
      throw CheckInLocationException(
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Não foi possível obter localização.',
      );
    }
  }

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}

class CheckInLocationException implements Exception {
  const CheckInLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
