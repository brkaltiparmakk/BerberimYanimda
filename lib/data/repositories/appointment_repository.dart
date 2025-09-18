import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';

class AppointmentRepository {
  AppointmentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Appointment>> fetchAppointments({String? businessId}) async {
    final query = _client
        .from('appointments')
        .select<List<Map<String, dynamic>>>(
          'id, business_id, customer_id, staff_id, status, total_amount, scheduled_at, services, payment_status',
        )
        .order('scheduled_at', ascending: false);

    if (businessId != null) {
      query.eq('business_id', businessId);
    }

    final response = await query;
    return response.map(Appointment.fromJson).toList();
  }

  Future<Appointment> bookAppointment({
    required String customerId,
    required String businessId,
    String? staffId,
    required List<String> serviceIds,
    required DateTime scheduledAt,
  }) async {
    final response = await _client.functions.invoke('book_appointment', body: {
      'customer_id': customerId,
      'business_id': businessId,
      'staff_id': staffId,
      'services': serviceIds,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    });

    if (response.error != null) {
      throw response.error!;
    }

    final data = response.data as Map<String, dynamic>;
    return Appointment.fromJson(data);
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    await _client
        .from('appointments')
        .update({
          'status': 'cancelled',
          'cancellation_reason': reason,
          'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', appointmentId);
  }

  Stream<List<Appointment>> watchAppointments(String businessId) {
    final controller = StreamController<List<Appointment>>();
    final channel = _client.channel('appointments:business_$businessId');

    channel
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'appointments',
          filter: 'business_id=eq.$businessId',
        ),
        (payload, [ref]) async {
          final data = await fetchAppointments(businessId: businessId);
          controller.add(data);
        },
      )
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'appointments',
          filter: 'business_id=eq.$businessId',
        ),
        (payload, [ref]) async {
          final data = await fetchAppointments(businessId: businessId);
          controller.add(data);
        },
      )
      ..subscribe();

    controller.onCancel = () => channel.unsubscribe();

    return controller.stream;
  }

  Stream<Map<String, dynamic>> dashboardStream(String businessId) async* {
    yield await _calculateSnapshot(businessId);
    await for (final _ in watchAppointments(businessId)) {
      yield await _calculateSnapshot(businessId);
    }
  }

  Future<Map<String, dynamic>> _calculateSnapshot(String businessId) async {
    final totals = await _client.rpc('business_dashboard_metrics', params: {'p_business_id': businessId});
    return totals as Map<String, dynamic>? ?? {};
  }
}
