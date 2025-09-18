import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/theme.dart';
import '../data/models/appointment.dart';
import '../data/models/business.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/business_repository.dart';
import '../data/repositories/promotion_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../data/services/notifications_service.dart';
import '../data/services/supabase_client.dart';
import 'availability_utils.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => SupabaseService.client);

final themeProvider = Provider<ThemeData>((ref) => AppTheme.light());
final darkThemeProvider = Provider<ThemeData>((ref) => AppTheme.dark());

final routerProvider = Provider<GoRouter>((ref) => AppRouter.createRouter());

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService(ref.watch(supabaseClientProvider));
});

class ExploreFilters {
  const ExploreFilters({this.query = '', this.minRating});

  final String query;
  final double? minRating;

  ExploreFilters copyWith({String? query, double? minRating}) => ExploreFilters(
        query: query ?? this.query,
        minRating: minRating ?? this.minRating,
      );
}

class ExploreFiltersNotifier extends StateNotifier<ExploreFilters> {
  ExploreFiltersNotifier() : super(const ExploreFilters());

  void updateQuery(String query) => state = state.copyWith(query: query);
  void updateRating(double? rating) => state = state.copyWith(minRating: rating);
  void reset() => state = const ExploreFilters();
}

final exploreFiltersProvider = StateNotifierProvider<ExploreFiltersNotifier, ExploreFilters>((ref) {
  return ExploreFiltersNotifier();
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(ref.watch(supabaseClientProvider));
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(supabaseClientProvider));
});

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.watch(supabaseClientProvider));
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(supabaseClientProvider));
});

final exploreProvider = FutureProvider<List<Business>>((ref) async {
  final filters = ref.watch(exploreFiltersProvider);
  return ref.watch(businessRepositoryProvider).fetchBusinesses(
        query: filters.query,
        minRating: filters.minRating,
      );
});

class AppointmentsNotifier extends StateNotifier<AsyncValue<List<Appointment>>> {
  AppointmentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final AppointmentRepository _repository;
  StreamSubscription<List<Appointment>>? _subscription;

  Future<void> _load() async {
    try {
      final data = await _repository.fetchAppointments();
      state = AsyncValue.data(data);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refresh() => _load();

  void watchBusiness(String businessId) {
    _subscription?.cancel();
    _subscription = _repository.watchAppointments(businessId).listen((appointments) {
      state = AsyncValue.data(appointments);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final appointmentsProvider = StateNotifierProvider<AppointmentsNotifier, AsyncValue<List<Appointment>>>((ref) {
  return AppointmentsNotifier(ref.watch(appointmentRepositoryProvider));
});

class BookingState {
  const BookingState({
    this.businessId,
    this.staffId,
    this.scheduledAt,
    this.services = const <String>{},
  });

  final String? businessId;
  final String? staffId;
  final DateTime? scheduledAt;
  final Set<String> services;

  BookingState copyWith({
    String? businessId,
    String? staffId,
    DateTime? scheduledAt,
    Set<String>? services,
  }) {
    return BookingState(
      businessId: businessId ?? this.businessId,
      staffId: staffId ?? this.staffId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      services: services ?? this.services,
    );
  }

  bool get isValid => businessId != null && services.isNotEmpty && scheduledAt != null;
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(const BookingState());

  void selectBusiness(String businessId) {
    state = state.copyWith(businessId: businessId, services: <String>{});
  }

  void toggleService(String serviceId) {
    final updated = Set<String>.from(state.services);
    if (updated.contains(serviceId)) {
      updated.remove(serviceId);
    } else {
      updated.add(serviceId);
    }
    state = state.copyWith(services: updated);
  }

  void selectStaff(String? staffId) => state = state.copyWith(staffId: staffId);
  void selectDateTime(DateTime dateTime) => state = state.copyWith(scheduledAt: dateTime);
  void clear() => state = const BookingState();
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});

final promotionsProvider = FutureProvider((ref) {
  return ref.watch(promotionRepositoryProvider).fetchActivePromotions();
});

final businessDashboardProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, businessId) {
  return ref.watch(appointmentRepositoryProvider).dashboardStream(businessId);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

class AvailabilityParams {
  const AvailabilityParams({required this.businessId, required this.date});

  final String businessId;
  final DateTime date;
}

final availabilityProvider = FutureProvider.family<List<DateTime>, AvailabilityParams>((ref, params) async {
  final client = ref.watch(supabaseClientProvider);
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final availability = await client
      .from('availability')
      .select<List<Map<String, dynamic>>>(
        'starts_at, ends_at',
      )
      .eq('business_id', params.businessId)
      .gte('starts_at', startOfDay.toUtc().toIso8601String())
      .lt('starts_at', endOfDay.toUtc().toIso8601String());

  final appointments = await client
      .from('appointments')
      .select<List<Map<String, dynamic>>>(
        'scheduled_at, duration_minutes',
      )
      .eq('business_id', params.businessId)
      .gte('scheduled_at', startOfDay.toUtc().toIso8601String())
      .lt('scheduled_at', endOfDay.toUtc().toIso8601String())
      .in_('status', ['pending', 'approved']);

  final taken = appointments
      .map((appointment) {
        final start = DateTime.parse(appointment['scheduled_at'] as String).toLocal();
        final duration = Duration(minutes: appointment['duration_minutes'] as int? ?? 30);
        return generateOccupiedSlots(start, duration);
      })
      .expand((element) => element)
      .toSet();

  final slots = <DateTime>[];
  for (final slot in availability) {
    final start = DateTime.parse(slot['starts_at'] as String).toLocal();
    final end = DateTime.parse(slot['ends_at'] as String).toLocal();
    var pointer = start;
    while (pointer.isBefore(end)) {
      if (!taken.contains(pointer)) {
        slots.add(pointer);
      }
      pointer = pointer.add(const Duration(minutes: 30));
    }
  }
  slots.sort();
  return slots;
});
