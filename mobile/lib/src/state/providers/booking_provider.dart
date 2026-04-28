import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/state/providers/auth_provider.dart';
import 'package:berber_yanimda/src/state/providers/catalog_provider.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

class BookingState {
  const BookingState({
    this.selectedServiceIds = const {},
    this.selectedStaff,
    this.selectedDate,
    this.slots = const [],
    this.selectedSlot,
    this.lastCreatedAppointment,
    this.paymentSessionId,
    this.isOnlinePayment = false,
    this.isBusy = false,
    this.errorMessage,
  });

  final Set<String> selectedServiceIds;
  final Staff? selectedStaff;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final Appointment? lastCreatedAppointment;
  final String? paymentSessionId;
  final bool isOnlinePayment;
  final bool isBusy;
  final String? errorMessage;

  BookingState copyWith({
    Set<String>? selectedServiceIds,
    Staff? selectedStaff,
    bool clearStaff = false,
    DateTime? selectedDate,
    List<TimeSlot>? slots,
    TimeSlot? selectedSlot,
    bool clearSlot = false,
    Appointment? lastCreatedAppointment,
    String? paymentSessionId,
    bool? isOnlinePayment,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookingState(
      selectedServiceIds: selectedServiceIds ?? this.selectedServiceIds,
      selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      lastCreatedAppointment: lastCreatedAppointment ?? this.lastCreatedAppointment,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      isOnlinePayment: isOnlinePayment ?? this.isOnlinePayment,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  List<BarberService> getSelectedServices(Barber? barber) {
    if (barber == null) return [];
    return barber.services
        .where((s) => selectedServiceIds.contains(s.id))
        .toList();
  }

  int getTotalDuration(Barber? barber) {
    return getSelectedServices(barber).fold(0, (t, s) => t + s.durationMinutes);
  }

  int getTotalPrice(Barber? barber) {
    return getSelectedServices(barber).fold(0, (t, s) => t + s.price);
  }
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  BookingRepository get _booking => ref.read(bookingRepositoryProvider);
  CatalogNotifier get _catalog => ref.read(catalogProvider.notifier);
  bool get _isLoggedIn => ref.read(authProvider).isLoggedIn;

  void selectBarber(Barber barber) {
    _catalog.selectBarber(barber);
    state = const BookingState().copyWith(selectedDate: DateTime.now().add(const Duration(days: 1)));
  }

  void toggleService(String serviceId) {
    final updated = Set<String>.from(state.selectedServiceIds);
    if (updated.contains(serviceId)) {
      updated.remove(serviceId);
    } else {
      updated.add(serviceId);
    }
    state = state.copyWith(
      selectedServiceIds: updated,
      clearSlot: true,
      slots: const [],
    );
  }

  void selectStaff(Staff? staff) {
    state = state.copyWith(selectedStaff: staff, clearStaff: staff == null, clearSlot: true, slots: const []);
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, clearSlot: true);
    await loadSlots();
  }

  Future<void> loadSlots() async {
    final barber = ref.read(catalogProvider).selectedBarber;
    if (barber == null || state.selectedServiceIds.isEmpty) {
      state = state.copyWith(slots: const []);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final serviceIds = state.getSelectedServices(barber).map((s) => s.id).toList();
      final slots = await _booking.getAvailability(
        barberShopId: barber.id,
        staffMemberId: state.selectedStaff?.id,
        serviceIds: serviceIds,
        date: state.selectedDate!,
      );
      state = state.copyWith(slots: slots);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    state = state.copyWith(selectedSlot: slot);
  }

  Future<bool> createPayAtBarberAppointment() async {
    if (!_isLoggedIn) {
      state = state.copyWith(errorMessage: 'Randevu oluşturmak için giriş yapmalısınız.');
      return false;
    }

    final barber = ref.read(catalogProvider).selectedBarber;
    final slot = state.selectedSlot;
    if (barber == null || slot == null) {
      state = state.copyWith(errorMessage: 'Randevu bilgileri eksik.');
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final appointment = await _booking.createAppointment(
        barberShopId: barber.id,
        staffMemberId: state.selectedStaff?.id,
        date: state.selectedDate!,
        startTime: slot.startTime,
        serviceIds: state.getSelectedServices(barber).map((s) => s.id).toList(),
      );
      await _booking.payAtBarber(appointment.id);
      state = state.copyWith(lastCreatedAppointment: appointment);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> createOnlinePaymentSession() async {
    final appointment = state.lastCreatedAppointment;
    if (appointment == null) {
      state = state.copyWith(errorMessage: 'Randevu bilgisi bulunamadı.');
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _booking.createOnlinePaymentSession(appointment.id);
      state = state.copyWith(
        paymentSessionId: session['sessionId'] as String?,
        isOnlinePayment: true,
      );
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> sandboxCompletePayment(bool success) async {
    if (state.paymentSessionId == null || state.paymentSessionId!.isEmpty) {
      state = state.copyWith(errorMessage: 'Odeme oturumu bulunamadı.');
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _booking.sandboxCompletePayment(state.paymentSessionId!, success);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void setPaymentMethod(bool online) {
    state = state.copyWith(isOnlinePayment: online);
  }

  void clearBooking() {
    state = const BookingState();
  }
}
