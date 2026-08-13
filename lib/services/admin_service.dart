import 'api_client.dart';

class AdminService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> simulateDisaster({
    required String category,
    required String severity,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    double affectedRadiusKm = 25,
  }) async {
    final json = await _api.post('/api/admin/disasters/simulate', {
      'category': category,
      'severity': severity,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'affectedRadiusKm': affectedRadiusKm,
    });
    return json as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchDisasters() async => (await _api.get('/api/admin/disasters')) as List;
  Future<List<dynamic>> fetchUsers() async => (await _api.get('/api/admin/users')) as List;
  Future<List<dynamic>> fetchNotifications() async => (await _api.get('/api/admin/notifications')) as List;
}
