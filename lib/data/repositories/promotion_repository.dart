import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promotion.dart';

class PromotionRepository {
  PromotionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Promotion>> fetchActivePromotions() async {
    final response = await _client
        .from('promotions')
        .select<List<Map<String, dynamic>>>(
          'id, business_id, title, description, discount_rate, start_date, end_date, active',
        )
        .eq('active', true)
        .gte('end_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: false);
    return response.map(Promotion.fromJson).toList();
  }
}
