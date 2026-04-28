import 'package:berber_yanimda/src/data/api_client.dart';
import 'package:berber_yanimda/src/data/models.dart';

class CouponRepository {
  CouponRepository(this._api);
  final ApiClient _api;

  Future<CouponValidationResult> validate({
    required String code,
    required int orderAmount,
  }) async {
    final response = await _api.post('/coupons/validate', {
      'code': code,
      'orderAmount': orderAmount,
    });
    return CouponValidationResult.fromJson(response['data'] as Map<String, dynamic>);
  }
}
