import 'package:berber_yanimda/src/data/api_client.dart';

class FcmTokenRepository {
  FcmTokenRepository(this._api);
  final ApiClient _api;

  Future<void> registerToken(String token, String platform) async {
    await _api.post('/users/me/device-token', {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterToken(String token) async {
    await _api.delete('/users/me/device-token', body: {'token': token});
  }
}
