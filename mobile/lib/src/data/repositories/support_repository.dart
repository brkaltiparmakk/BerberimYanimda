import 'package:berber_yanimda/src/data/api_client.dart';

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  Future<void> create(String subject, String description) async {
    await _api.post('/support-tickets', {
      'subject': subject,
      'description': description,
    });
  }
}
