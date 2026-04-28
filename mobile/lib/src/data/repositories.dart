import 'package:berber_yanimda/src/data/api_client.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<bool> hasSession() => _api.hasAccessToken();

  Future<UserProfile> login(String phoneNumber, String password) async {
    final response = await _api.post('/auth/login', {
      'phoneNumber': phoneNumber,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>?;
    await _api.saveTokens(
      (tokens?['accessToken'] ?? data['accessToken']) as String,
      (tokens?['refreshToken'] ?? data['refreshToken']) as String,
    );
    return UserProfile.fromJson((data['user'] as Map<String, dynamic>?) ?? data);
  }

  Future<void> register(
    String fullName,
    String phoneNumber,
    String email,
    String password,
  ) async {
    await _api.post('/auth/register', {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
    });
  }

  Future<void> verifyOtp(String phoneNumber, String code) async {
    await _api.post('/auth/verify-otp', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
  }

  Future<String?> getRefreshToken() async {
    return await _api.getRefreshToken();
  }

  Future<void> logoutFromServer(String refreshToken) async {
    try {
      await _api.post('/auth/logout', {'refreshToken': refreshToken});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout request failed: $e');
      }
    }
  }

  Future<void> logout() => _api.clearTokens();
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<UserProfile> me() async {
    final response = await _api.get('/users/me');
    return UserProfile.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> update({
    required String fullName,
    String? email,
    String? birthDate,
  }) async {
    final response = await _api.put('/users/me', {
      'fullName': fullName,
      'email': email,
      'birthDate': birthDate,
    });
    return UserProfile.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> uploadProfileImage(String filePath) async {
    final response = await _api.postMultipartFile(
      '/users/me/profile-image',
      fieldName: 'file',
      filePath: filePath,
    );
    return UserProfile.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/users/me/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    await _api.post('/users/me/delete-account', {
      'password': password,
    });
  }

  Future<Map<String, dynamic>> exportData() async {
    final response = await _api.get('/users/me/export-data');
    return response['data'] as Map<String, dynamic>;
  }
}

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<List<Barber>> getBarbers() async {
    final response = await _api.get('/barbers?page=1&pageSize=50');
    final data = response['data'] as Map<String, dynamic>;
    return ((data['items'] as List<dynamic>?) ?? [])
        .map((item) => Barber.fromListJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Barber> getBarber(String id) async {
    final response = await _api.get('/barbers/$id');
    return Barber.fromDetailJson(response['data'] as Map<String, dynamic>);
  }
}

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<List<TimeSlot>> getAvailability({
    required String barberShopId,
    required String? staffMemberId,
    required List<String> serviceIds,
    required DateTime date,
  }) async {
    final staffQuery = staffMemberId == null
        ? ''
        : '&staffMemberId=${Uri.encodeComponent(staffMemberId)}';
    final response = await _api.get(
      '/availability?barberShopId=${Uri.encodeComponent(barberShopId)}'
      '&serviceIds=${Uri.encodeComponent(serviceIds.join(','))}'
      '&date=${Uri.encodeComponent(_date(date))}'
      '$staffQuery',
    );
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> createAppointment({
    required String barberShopId,
    required String? staffMemberId,
    required DateTime date,
    required String startTime,
    required List<String> serviceIds,
    String? customerNote,
  }) async {
    final response = await _api.post('/appointments', {
      'barberShopId': barberShopId,
      'staffMemberId': staffMemberId,
      'appointmentDate': _date(date),
      'startTime': startTime,
      'serviceIds': serviceIds,
      'customerNote': customerNote,
    });
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> payAtBarber(String appointmentId) async {
    await _api.post('/payments/pay-at-barber', {
      'appointmentId': appointmentId,
    });
  }

  Future<Map<String, dynamic>> createOnlinePaymentSession(String appointmentId) async {
    final response = await _api.post('/payments/create-session', {
      'appointmentId': appointmentId,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> sandboxCompletePayment(String sessionId, bool success) async {
    await _api.post('/payments/sandbox/complete', {
      'sessionId': sessionId,
      'success': success,
    });
  }

  Future<List<Appointment>> getMine() async {
    final response = await _api.get('/appointments/my');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> cancel(String appointmentId, {String? reason}) async {
    final response = await _api.post('/appointments/$appointmentId/cancel', {
      'reason': reason,
    });
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Appointment>> getShopAppointments({DateTime? date, AppointmentStatus? status}) async {
    final query = <String>[];
    if (date != null) query.add('date=${Uri.encodeComponent(_date(date))}');
    if (status != null) query.add('status=${Uri.encodeComponent(status.name)}');
    final response = await _api.get('/appointments/shop${query.isEmpty ? '' : '?${query.join('&')}'}');
    final data = response['data'] as Map<String, dynamic>;
    return ((data['items'] as List<dynamic>?) ?? [])
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> confirmAppointment(String id) async {
    final response = await _api.patch('/appointments/$id/confirm', {});
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Appointment> completeAppointment(String id) async {
    final response = await _api.patch('/appointments/$id/complete', {});
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Appointment> rejectAppointment(String id, {String? reason}) async {
    final response = await _api.patch('/appointments/$id/reject', {'reason': reason});
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }
}

class FavoriteRepository {
  FavoriteRepository(this._api);
  final ApiClient _api;

  Future<List<Barber>> getFavorites() async {
    final response = await _api.get('/favorites');
    return ((response['data'] as List<dynamic>?) ?? []).map((item) {
      final json = item as Map<String, dynamic>;
      return Barber(
        id: json['barberShopId'] as String,
        name: json['name'] as String,
        district: json['district'] as String,
        city: json['city'] as String,
        rating: ((json['rating'] as num?) ?? 0).toDouble(),
        reviewCount: 0,
        distanceKm: 0,
        startingPrice: 0,
        isAvailableToday: true,
        imageUrl: (json['coverImageUrl'] as String?) ?? '',
        isFavorite: true,
        description: '',
        address: '',
        services: const [],
        staff: const [],
      );
    }).toList();
  }

  Future<void> add(String barberShopId) async {
    await _api.post('/favorites/$barberShopId', {});
  }

  Future<void> remove(String barberShopId) async {
    await _api.delete('/favorites/$barberShopId');
  }
}

class NotificationRepository {
  NotificationRepository(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> getMine() async {
    final response = await _api.get('/notifications');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    await _api.post('/notifications/$notificationId/read', {});
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all', {});
  }
}

class ReviewRepository {
  ReviewRepository(this._api);
  final ApiClient _api;

  Future<Review> create({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    final response = await _api.post('/reviews', {
      'appointmentId': appointmentId,
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Review>> getByBarberShop(String barberShopId) async {
    final response = await _api.get('/barbers/$barberShopId/reviews');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewSummary> getSummary(String barberShopId) async {
    final response = await _api.get('/barbers/$barberShopId/reviews/summary');
    return ReviewSummary.fromJson(response['data'] as Map<String, dynamic>);
  }
}

class BarberOwnerRepository {
  BarberOwnerRepository(this._api);
  final ApiClient _api;

  Future<List<WorkingHour>> getWorkingHours() async {
    final response = await _api.get('/barber-owner/working-hours');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => WorkingHour.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateWorkingHours(List<WorkingHour> hours) async {
    await _api.put('/barber-owner/working-hours', {
      'workingHours': hours.map((h) => h.toJson()).toList(),
    });
  }

  Future<List<OwnerService>> getServices() async {
    final response = await _api.get('/barber-owner/services');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => OwnerService.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerService> createService({
    required String name,
    String? description,
    required int durationMinutes,
    required int price,
  }) async {
    final response = await _api.post('/barber-owner/services', {
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
    });
    return OwnerService.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<OwnerService> updateService({
    required String id,
    required String name,
    String? description,
    required int durationMinutes,
    required int price,
  }) async {
    final response = await _api.put('/barber-owner/services/$id', {
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
    });
    return OwnerService.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _api.delete('/barber-owner/services/$id');
  }

  Future<List<OwnerStaff>> getStaff() async {
    final response = await _api.get('/barber-owner/staff');
    return ((response['data'] as List<dynamic>?) ?? [])
        .map((item) => OwnerStaff.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerStaff> createStaff({
    required String fullName,
    String? expertise,
    String? bio,
  }) async {
    final response = await _api.post('/barber-owner/staff', {
      'fullName': fullName,
      'expertise': expertise,
      'bio': bio,
    });
    return OwnerStaff.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<OwnerStaff> updateStaff({
    required String id,
    required String fullName,
    String? expertise,
    String? bio,
  }) async {
    final response = await _api.put('/barber-owner/staff/$id', {
      'fullName': fullName,
      'expertise': expertise,
      'bio': bio,
    });
    return OwnerStaff.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStaff(String id) async {
    await _api.delete('/barber-owner/staff/$id');
  }

  Future<void> assignStaffServices(String staffId, List<String> serviceIds) async {
    await _api.put('/barber-owner/staff/$staffId/services', {
      'serviceIds': serviceIds,
    });
  }
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
