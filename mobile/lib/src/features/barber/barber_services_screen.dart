import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BarberServicesScreen extends ConsumerStatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  ConsumerState<BarberServicesScreen> createState() => _BarberServicesScreenState();
}

class _BarberServicesScreenState extends ConsumerState<BarberServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barberOwnerProvider.notifier).loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(barberOwnerProvider);
    final services = owner.services;

    return AppScaffold(
      currentIndex: 0,
      title: 'Hizmetler',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Hizmet Ekle'),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async { await ref.read(barberOwnerProvider.notifier).loadServices(); },
              child: services.isEmpty
                  ? const Center(child: Text('Henüz hizmet eklenmemiş.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return _ServiceCard(
                          service: service,
                          onEdit: () => _showForm(context, service: service),
                          onDelete: () => _delete(context, service.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {OwnerService? service}) async {
    final result = await showDialog<_ServiceFormResult>(
      context: context,
      builder: (context) => _ServiceFormDialog(service: service),
    );
    if (result == null) return;

    final state = ref.read(barberOwnerProvider);
    final success = service == null
        ? await ref.read(barberOwnerProvider.notifier).createService(
            name: result.name,
            description: result.description,
            durationMinutes: result.durationMinutes,
            price: result.price,
          )
        : await ref.read(barberOwnerProvider.notifier).updateService(
            id: service.id,
            name: result.name,
            description: result.description,
            durationMinutes: result.durationMinutes,
            price: result.price,
          );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? service == null
                  ? 'Hizmet eklendi.'
                  : 'Hizmet güncellendi.'
              : 'Hata: ${state.errorMessage}'),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Hizmeti Sil'),
        content: const Text('Bu hizmeti silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final state = ref.read(barberOwnerProvider);
    final success = await ref.read(barberOwnerProvider.notifier).deleteService(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Hizmet silindi.' : 'Hata: ${state.errorMessage}')),
      );
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final OwnerService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(service.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${service.durationMinutes} dk • ₺${service.price}${service.description != null ? '\n${service.description}' : ''}',
          style: AppTextStyles.caption,
        ),
        isThreeLine: service.description != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceFormResult {
  final String name;
  final String? description;
  final int durationMinutes;
  final int price;

  _ServiceFormResult({
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
  });
}

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({this.service});

  final OwnerService? service;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _durationController = TextEditingController(text: widget.service?.durationMinutes.toString() ?? '');
    _priceController = TextEditingController(text: widget.service?.price.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(widget.service == null ? 'Yeni Hizmet' : 'Hizmeti Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hizmet Adı'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Açıklama (isteğe bağlı)'),
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Süre (dakika)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final duration = int.tryParse(_durationController.text.trim()) ?? 0;
            final price = int.tryParse(_priceController.text.trim()) ?? 0;
            if (name.isEmpty || duration <= 0 || price < 0) return;
            Navigator.pop(context, _ServiceFormResult(
              name: name,
              description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
              durationMinutes: duration,
              price: price,
            ));
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
