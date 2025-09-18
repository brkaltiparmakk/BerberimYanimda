import 'package:berberim_yanimda/data/models/appointment.dart';
import 'package:berberim_yanimda/data/repositories/appointment_repository.dart';
import 'package:berberim_yanimda/state/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _MockAppointmentRepository extends Mock implements AppointmentRepository {}

void main() {
  test('appointmentsProvider yükleme sonrasında data döner', () async {
    final mockRepository = _MockAppointmentRepository();
    final sample = Appointment(
      id: 'appt-1',
      businessId: 'biz-1',
      customerId: 'cust-1',
      status: 'pending',
      totalAmount: 150,
      scheduledAt: DateTime.parse('2024-01-01T10:00:00Z'),
    );
    when(() => mockRepository.fetchAppointments()).thenAnswer((_) async => <Appointment>[sample]);

    final container = ProviderContainer(
      overrides: [appointmentRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await container.read(appointmentsProvider.notifier).refresh();
    final state = container.read(appointmentsProvider);

    expect(state, isA<AsyncData<List<Appointment>>>());
    verify(() => mockRepository.fetchAppointments()).called(2);
  });
}
