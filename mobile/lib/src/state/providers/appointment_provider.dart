import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/state/providers/auth_provider.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appointmentProvider = NotifierProvider<AppointmentNotifier, AppointmentState>(
  AppointmentNotifier.new,
);

class AppointmentState {
  const AppointmentState({
    this.appointments = const [],
    this.filter = AppointmentFilter.upcoming,
    this.isBusy = false,
    this.errorMessage,
  });

  final List<Appointment> appointments;
  final AppointmentFilter filter;
  final bool isBusy;
  final String? errorMessage;

  List<Appointment> get filtered {
    return switch (filter) {
      AppointmentFilter.upcoming => appointments
          .where((a) => a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.upcoming ||
              a.status == AppointmentStatus.pending)
          .toList(),
      AppointmentFilter.past => appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .toList(),
      AppointmentFilter.cancelled => appointments
          .where((a) => a.status == AppointmentStatus.cancelled ||
              a.status == AppointmentStatus.rejected ||
              a.status == AppointmentStatus.noShow)
          .toList(),
    };
  }

  AppointmentState copyWith({
    List<Appointment>? appointments,
    AppointmentFilter? filter,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      filter: filter ?? this.filter,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AppointmentNotifier extends Notifier<AppointmentState> {
  @override
  AppointmentState build() => const AppointmentState();

  BookingRepository get _booking => ref.read(bookingRepositoryProvider);
  bool get _isLoggedIn => ref.read(authProvider).isLoggedIn;

  Future<void> loadAppointments() async {
    if (!_isLoggedIn) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final appointments = await _booking.getMine();
      state = state.copyWith(appointments: appointments);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> cancelAppointment(String id) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final cancelled = await _booking.cancel(id);
      final updated = state.appointments.map((a) => a.id == id ? cancelled : a).toList();
      state = state.copyWith(appointments: updated);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void setFilter(AppointmentFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void clear() {
    state = const AppointmentState();
  }
}
