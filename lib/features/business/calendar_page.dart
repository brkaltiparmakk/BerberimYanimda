import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/appointment.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class BusinessCalendarPage extends ConsumerStatefulWidget {
  const BusinessCalendarPage({super.key});

  @override
  ConsumerState<BusinessCalendarPage> createState() => _BusinessCalendarPageState();
}

class _BusinessCalendarPageState extends ConsumerState<BusinessCalendarPage> {
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;
  String? _businessId;
  List<Appointment> _appointments = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
    final profile = await ref.read(supabaseClientProvider)
        .from('profiles')
        .select<Map<String, dynamic>>('default_business_id')
        .maybeSingle();
    final businessId = profile?['default_business_id'] as String?;
    if (businessId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(appointmentRepositoryProvider);
    final data = await repo.fetchAppointments(businessId: businessId);
    setState(() {
      _businessId = businessId;
      _appointments = data;
      _loading = false;
    });
    _appointmentsSubscription = repo.watchAppointments(businessId).listen((event) {
      setState(() => _appointments = event);
    });
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.calendar_month, message: 'İşletme bilgisi eksik.'));
    }

    final grouped = <String, List<Appointment>>{};
    for (final appointment in _appointments) {
      final key = DateFormat.yMMMMd('tr_TR').format(appointment.scheduledAt.toLocal());
      grouped.putIfAbsent(key, () => []).add(appointment);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Takvimim')),
      body: grouped.isEmpty
          ? const EmptyState(icon: Icons.event_available, message: 'Gösterilecek randevu yok.')
          : ListView(
              children: grouped.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value
                      .map((appointment) => ListTile(
                            title: Text(DateFormat.Hm('tr_TR').format(appointment.scheduledAt.toLocal())),
                            subtitle: Text('Durum: ${appointment.status}'),
                            trailing: Text('${appointment.totalAmount.toStringAsFixed(0)} ₺'),
                          ))
                      .toList(),
                );
              }).toList(),
            ),
    );
  }
}
