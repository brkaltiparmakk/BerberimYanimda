import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/service.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class ServiceManagePage extends ConsumerStatefulWidget {
  const ServiceManagePage({super.key});

  @override
  ConsumerState<ServiceManagePage> createState() => _ServiceManagePageState();
}

class _ServiceManagePageState extends ConsumerState<ServiceManagePage> {
  List<ServiceModel> _services = const [];
  bool _loading = true;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      return;
    }
    final profile = await client
        .from('profiles')
        .select<Map<String, dynamic>>('default_business_id')
        .eq('id', userId)
        .maybeSingle();
    final businessId = profile?['default_business_id'] as String?;
    if (businessId == null) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(businessRepositoryProvider);
    final services = await repo.fetchServices(businessId);
    if (!mounted) {
      return;
    }
    setState(() {
      _businessId = businessId;
      _services = services;
      _loading = false;
    });
  }

  Future<void> _saveService({ServiceModel? service}) async {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final priceCtrl = TextEditingController(text: service?.price.toString() ?? '');
    final durationCtrl = TextEditingController(text: service?.durationMinutes.toString() ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(service == null ? 'Hizmet Ekle' : 'Hizmeti Güncelle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Hizmet Adı')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Fiyat'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Süre (dk)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Açıklama')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final client = ref.read(supabaseClientProvider);
                  if (service == null) {
                    await client.from('services').insert({
                      'business_id': _businessId,
                      'name': nameCtrl.text,
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                      'description': descCtrl.text,
                    });
                  } else {
                    await client.from('services').update({
                      'name': nameCtrl.text,
                      'price': double.tryParse(priceCtrl.text) ?? service.price,
                      'duration_minutes': int.tryParse(durationCtrl.text) ?? service.durationMinutes,
                      'description': descCtrl.text,
                    }).eq('id', service.id);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    _load();
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.design_services, message: 'İşletme bulunamadı.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hizmet Yönetimi'), actions: [
        IconButton(onPressed: () => _saveService(), icon: const Icon(Icons.add)),
      ]),
      body: _services.isEmpty
          ? const EmptyState(icon: Icons.design_services, message: 'Henüz hizmet eklemediniz.')
          : ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return ListTile(
                  title: Text(service.name),
                  subtitle: Text('${service.price.toStringAsFixed(0)} ₺ • ${service.durationMinutes} dk'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _saveService(service: service),
                  ),
                );
              },
            ),
    );
  }
}
