import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/appointment.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';
import 'appointment_card.dart';

class MyAppointmentsPage extends ConsumerWidget {
  const MyAppointmentsPage({super.key});

  List<Appointment> _filter(List<Appointment> appointments, String status) {
    switch (status) {
      case 'upcoming':
        return appointments.where((a) => a.status == 'pending' || a.status == 'approved').toList();
      case 'past':
        return appointments.where((a) => a.status == 'completed').toList();
      case 'cancelled':
        return appointments.where((a) => a.status == 'cancelled').toList();
      default:
        return appointments;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Randevularım'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Geçmiş'),
              Tab(text: 'İptal'),
            ],
          ),
        ),
        body: appointmentsAsync.when(
          data: (appointments) {
            return TabBarView(
              children: [
                _buildList(context, ref, _filter(appointments, 'upcoming')),
                _buildList(context, ref, _filter(appointments, 'past')),
                _buildList(context, ref, _filter(appointments, 'cancelled')),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Randevular yüklenemedi: $error')),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Appointment> items) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.event_busy, message: 'Henüz randevunuz yok.');
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appointment = items[index];
        return AppointmentCard(
          appointment: appointment,
          onCancel: () async {
            await ref.read(appointmentRepositoryProvider).cancelAppointment(appointment.id);
            ref.read(appointmentsProvider.notifier).refresh();
          },
          onRate: () => context.go('/rate/${appointment.id}'),
        );
      },
    );
  }
}
