import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/service.dart';
import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class SelectServicePage extends ConsumerStatefulWidget {
  const SelectServicePage({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<SelectServicePage> createState() => _SelectServicePageState();
}

class _SelectServicePageState extends ConsumerState<SelectServicePage> {
  bool _loading = true;
  List<ServiceModel> _services = const [];

  @override
  void initState() {
    super.initState();
    ref.read(bookingProvider.notifier).selectBusiness(widget.businessId);
    _load();
  }

  Future<void> _load() async {
    final services = await ref.read(businessRepositoryProvider).fetchServices(widget.businessId);
    if (!mounted) {
      return;
    }
    setState(() {
      _services = services;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hizmet Seçin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final service = _services[index];
                final selected = state.services.contains(service.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => ref.read(bookingProvider.notifier).toggleService(service.id),
                  title: Text(service.name),
                  subtitle: Text('${service.durationMinutes} dk • ${service.price.toStringAsFixed(0)} ₺'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _services.length,
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          onPressed: state.services.isEmpty ? null : () => context.go('/booking/datetime/${widget.businessId}'),
          label: 'Devam Et',
        ),
      ),
    );
  }
}
