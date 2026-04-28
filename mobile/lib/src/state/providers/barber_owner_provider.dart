import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/state/providers/auth_provider.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final barberOwnerProvider = NotifierProvider<BarberOwnerNotifier, BarberOwnerState>(
  BarberOwnerNotifier.new,
);

class BarberOwnerState {
  const BarberOwnerState({
    this.appointments = const [],
    this.workingHours = const [],
    this.services = const [],
    this.staff = const [],
    this.filterDate,
    this.filterStatus,
    this.isBusy = false,
    this.errorMessage,
  });

  final List<Appointment> appointments;
  final List<WorkingHour> workingHours;
  final List<OwnerService> services;
  final List<OwnerStaff> staff;
  final DateTime? filterDate;
  final AppointmentStatus? filterStatus;
  final bool isBusy;
  final String? errorMessage;

  int get pendingCount => appointments.where((a) => a.status == AppointmentStatus.pending).length;
  int get todayCount => appointments.where((a) {
    final now = DateTime.now();
    return a.status == AppointmentStatus.confirmed &&
        a.dateTime.year == now.year && a.dateTime.month == now.month && a.dateTime.day == now.day;
  }).length;

  BarberOwnerState copyWith({
    List<Appointment>? appointments, List<WorkingHour>? workingHours,
    List<OwnerService>? services, List<OwnerStaff>? staff,
    DateTime? filterDate, AppointmentStatus? filterStatus,
    bool? isBusy, String? errorMessage, bool clearError = false,
  }) => BarberOwnerState(
    appointments: appointments ?? this.appointments,
    workingHours: workingHours ?? this.workingHours,
    services: services ?? this.services,
    staff: staff ?? this.staff,
    filterDate: filterDate ?? this.filterDate,
    filterStatus: filterStatus ?? this.filterStatus,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class BarberOwnerNotifier extends Notifier<BarberOwnerState> {
  @override
  BarberOwnerState build() => const BarberOwnerState();

  BookingRepository get _booking => ref.read(bookingRepositoryProvider);
  BarberOwnerRepository get _repo => ref.read(barberOwnerRepositoryProvider);
  bool get _isBarber => ref.read(authProvider).isBarber;

  Future<bool> loadAll() async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await Future.wait([
        _loadAppointmentsDirect(),
        _loadWorkingHoursDirect(),
        _loadServicesDirect(),
        _loadStaffDirect(),
      ]);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<List<Appointment>> _loadAppointmentsDirect() async {
    if (state.appointments.isEmpty) {
      final appointments = await _booking.getShopAppointments();
      state = state.copyWith(appointments: appointments);
      return appointments;
    }
    return state.appointments;
  }

  Future<List<WorkingHour>> _loadWorkingHoursDirect() async {
    if (state.workingHours.isEmpty) {
      final hours = await _repo.getWorkingHours();
      state = state.copyWith(workingHours: hours);
      return hours;
    }
    return state.workingHours;
  }

  Future<List<OwnerService>> _loadServicesDirect() async {
    if (state.services.isEmpty) {
      final services = await _repo.getServices();
      state = state.copyWith(services: services);
      return services;
    }
    return state.services;
  }

  Future<List<OwnerStaff>> _loadStaffDirect() async {
    if (state.staff.isEmpty) {
      final staff = await _repo.getStaff();
      state = state.copyWith(staff: staff);
      return staff;
    }
    return state.staff;
  }

  // ─── Appointments ─────────────────────────────────────────────────────────

  Future<bool> loadAppointments({DateTime? date, AppointmentStatus? status}) async {
    if (!_isBarber) return false;
    state = state.copyWith(filterDate: date, filterStatus: status, isBusy: true, clearError: true);
    try {
      final appointments = await _booking.getShopAppointments(date: date, status: status);
      state = state.copyWith(appointments: appointments);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> confirmAppointment(String id) async {
    return _modifyAppointment(id, () => _booking.confirmAppointment(id));
  }

  Future<bool> completeAppointment(String id) async {
    return _modifyAppointment(id, () => _booking.completeAppointment(id));
  }

  Future<bool> rejectAppointment(String id, {String? reason}) async {
    return _modifyAppointment(id, () => _booking.rejectAppointment(id, reason: reason));
  }

  Future<bool> _modifyAppointment(String id, Future<Appointment> Function() action) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await action();
      final appointments = state.appointments.map((a) => a.id == id ? updated : a).toList();
      state = state.copyWith(appointments: appointments);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  // ─── Working Hours ────────────────────────────────────────────────────────

  Future<bool> loadWorkingHours() async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final hours = await _repo.getWorkingHours();
      state = state.copyWith(workingHours: hours);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void updateWorkingHourLocally(WorkingHour updated) {
    final hours = [
      for (final h in state.workingHours)
        if (h.dayOfWeek == updated.dayOfWeek) updated else h,
      if (!state.workingHours.any((h) => h.dayOfWeek == updated.dayOfWeek)) updated,
    ];
    state = state.copyWith(workingHours: hours);
  }

  Future<bool> updateWorkingHours(List<WorkingHour> hours) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.updateWorkingHours(hours);
      state = state.copyWith(workingHours: hours);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  // ─── Services ─────────────────────────────────────────────────────────────

  Future<bool> loadServices() async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final services = await _repo.getServices();
      state = state.copyWith(services: services);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> createService({required String name, String? description, required int durationMinutes, required int price}) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final created = await _repo.createService(name: name, description: description, durationMinutes: durationMinutes, price: price);
      state = state.copyWith(services: [...state.services, created]);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> updateService({required String id, required String name, String? description, required int durationMinutes, required int price}) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.updateService(id: id, name: name, description: description, durationMinutes: durationMinutes, price: price);
      state = state.copyWith(services: state.services.map((s) => s.id == id ? updated : s).toList());
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> deleteService(String id) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.deleteService(id);
      state = state.copyWith(services: state.services.where((s) => s.id != id).toList());
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  // ─── Staff ────────────────────────────────────────────────────────────────

  Future<bool> loadStaff() async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final staff = await _repo.getStaff();
      state = state.copyWith(staff: staff);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> createStaff({required String fullName, String? expertise, String? bio}) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final created = await _repo.createStaff(fullName: fullName, expertise: expertise, bio: bio);
      state = state.copyWith(staff: [...state.staff, created]);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> updateStaff({required String id, required String fullName, String? expertise, String? bio}) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.updateStaff(id: id, fullName: fullName, expertise: expertise, bio: bio);
      state = state.copyWith(staff: state.staff.map((s) => s.id == id ? updated : s).toList());
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> deleteStaff(String id) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.deleteStaff(id);
      state = state.copyWith(staff: state.staff.where((s) => s.id != id).toList());
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> assignStaffServices(String staffId, List<String> serviceIds) async {
    if (!_isBarber) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.assignStaffServices(staffId, serviceIds);
      await loadStaff();
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
