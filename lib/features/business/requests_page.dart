import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/appointment.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class BusinessRequestsPage extends ConsumerStatefulWidget {
  const BusinessRequestsPage({super.key});

  @override
  ConsumerState<BusinessRequestsPage> createState() => _BusinessRequestsPageState();
}

class _BusinessRequestsPageState extends ConsumerState<BusinessRequestsPage> {
  List<Appointment> _requests = const [];
  bool _loading = true;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(supabaseClientProvider)
        .from('profiles')
        .select<Map<String, dynamic>>('default_business_id')
        .maybeSingle();
    final businessId = profile?['default_business_id'] as String?;
    if (businessId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(appointmentRepositoryProvider);
    final data = await repo.fetchAppointments(businessId: businessId);
    if (!mounted) return;
    setState(() {
      _businessId = businessId;
      _requests = data.where((appointment) => appointment.status == 'pending').toList();
      _loading = false;
    });
  }

  Future<void> _updateStatus(Appointment appointment, String status) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('appointments').update({'status': status}).eq('id', appointment.id);
    if (!mounted) return;
    setState(() {
      _requests = _requests.where((item) => item.id != appointment.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.store, message: 'İşletme bilgisi yok.'));
    }
    if (_requests.isEmpty) {
      return const Scaffold(body: EmptyState(icon: Icons.inbox, message: 'Bekleyen randevu talebi yok.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Talepleri')),
      body: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final appointment = _requests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Müşteri: ${appointment.customerId}'),
                  Text('Saat: ${appointment.formattedDate}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _updateStatus(appointment, 'approved'),
                          child: const Text('Onayla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(appointment, 'rejected'),
                          child: const Text('Reddet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
