import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business.dart';
import '../models/service.dart';
import '../models/staff_member.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  Future<List<Business>> fetchBusinesses({String? query, double? minRating}) async {
    final builder = _client
        .from('businesses')
        .select<List<Map<String, dynamic>>>(
          'id, name, description, address, latitude, longitude, cover_image_url, average_rating, review_count, published, open_hours',
        )
        .eq('published', true)
        .isFilter('deleted_at', null)
        .order('average_rating', ascending: false)
        .limit(50);

    if (query != null && query.isNotEmpty) {
      builder.or('name.ilike.%$query%,address.ilike.%$query%');
    }
    if (minRating != null) {
      builder.gte('average_rating', minRating);
    }

    final response = await builder;
    return response.map(Business.fromJson).toList();
  }

  Future<Business?> getBusiness(String id) async {
    final data = await _client
        .from('businesses')
        .select<Map<String, dynamic>>("*")
        .eq('id', id)
        .maybeSingle();
    return data != null ? Business.fromJson(data) : null;
  }

  Future<List<ServiceModel>> fetchServices(String businessId) async {
    final response = await _client
        .from('services')
        .select<List<Map<String, dynamic>>>(
          'id, business_id, name, description, price, duration_minutes, category_id, active',
        )
        .eq('business_id', businessId)
        .eq('active', true)
        .isFilter('deleted_at', null)
        .order('name');
    return response.map(ServiceModel.fromJson).toList();
  }

  Future<List<StaffMember>> fetchStaff(String businessId) async {
    final response = await _client
        .from('staff')
        .select<List<Map<String, dynamic>>>(
          'id, business_id, full_name, role, active, avatar_url',
        )
        .eq('business_id', businessId)
        .eq('active', true)
        .order('full_name');
    return response.map(StaffMember.fromJson).toList();
  }
}
