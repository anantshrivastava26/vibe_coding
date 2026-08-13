import '../models/alert.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _api = ApiClient();

  Future<List<DisasterAlert>> fetchMyAlerts() async {
    final json = await _api.get('/api/users/me/alerts') as List;
    return json.map((e) => DisasterAlert.fromJson(e as Map<String, dynamic>)).toList();
  }
}
