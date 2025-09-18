import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/service.dart';
import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class ConfirmBookingPage extends ConsumerStatefulWidget {
  const ConfirmBookingPage({super.key});

  @override
  ConsumerState<ConfirmBookingPage> createState() => _ConfirmBookingPageState();
}

class _ConfirmBookingPageState extends ConsumerState<ConfirmBookingPage> {
  bool _loading = true;
  bool _submitting = false;
  List<ServiceModel> _selectedServices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final booking = ref.read(bookingProvider);
    if (booking.businessId == null || booking.services.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final client = ref.read(supabaseClientProvider);
    final query = client.from('services').select<List<Map<String, dynamic>>>();
    query.eq('business_id', booking.businessId);
    query.in_('id', booking.services.toList());
    final response = await query;
    final services = response
        .map(
          (json) => ServiceModel(
            id: json['id'] as String,
            businessId: json['business_id'] as String,
            name: json['name'] as String,
            price: (json['price'] as num).toDouble(),
            durationMinutes: json['duration_minutes'] as int,
            active: json['active'] as bool? ?? true,
            description: json['description'] as String?,
            categoryId: json['category_id'] as String?,
          ),
        )
        .toList();
    setState(() {
      _selectedServices = services;
      _loading = false;
    });
  }

  Future<void> _book() async {
    final booking = ref.read(bookingProvider);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (!booking.isValid || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eksik bilgi var.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final appointment = await ref.read(appointmentRepositoryProvider).bookAppointment(
            customerId: userId,
            businessId: booking.businessId!,
            staffId: booking.staffId,
            serviceIds: booking.services.toList(),
            scheduledAt: booking.scheduledAt!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevunuz oluşturuldu: ${appointment.formattedDate}')),
      );
      ref.read(bookingProvider.notifier).clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu alınamadı: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingProvider);
    final total = _selectedServices.fold<double>(0, (sum, item) => sum + item.price);
    final duration = _selectedServices.fold<int>(0, (sum, item) => sum + item.durationMinutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Onay')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Özet', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ..._selectedServices.map(
                    (service) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(service.name),
                      trailing: Text('${service.price.toStringAsFixed(0)} ₺'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Toplam Süre'),
                    trailing: Text('$duration dk'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Toplam Tutar'),
                    trailing: Text('${total.toStringAsFixed(0)} ₺'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tarih & Saat'),
                    trailing: Text(
                      booking.scheduledAt != null
                          ? DateFormat.yMMMMEEEEd('tr_TR').add_Hm().format(booking.scheduledAt!.toLocal())
                          : '-',
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          onPressed: booking.isValid && !_submitting ? _book : null,
          label: _submitting ? 'Gönderiliyor...' : 'Randevuyu Onayla',
        ),
      ),
    );
  }
}
