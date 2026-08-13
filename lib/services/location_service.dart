import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_client.dart';

class LocationService {
  final ApiClient _api = ApiClient();

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return [p.locality, p.administrativeArea, p.country]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    return _api.put('/api/users/me/location', {
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': label,
    });
  }
}
