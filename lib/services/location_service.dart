import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_client.dart';

// A coordinate the user has chosen — from GPS, an address search, or a map tap.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String? label;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  String get coordinates =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

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

  // Forward-geocodes a free-text place name. Each hit is reverse-geocoded again
  // so the picker can show a readable address rather than bare coordinates.
  Future<List<PickedLocation>> searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    try {
      final results = await locationFromAddress(trimmed);
      return Future.wait(
        results.take(5).map((l) async => PickedLocation(
              latitude: l.latitude,
              longitude: l.longitude,
              label: await reverseGeocode(l.latitude, l.longitude) ?? trimmed,
            )),
      );
    } catch (_) {
      return [];
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
