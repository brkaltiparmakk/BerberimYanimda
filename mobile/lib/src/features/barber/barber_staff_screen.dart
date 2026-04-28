import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BarberStaffScreen extends ConsumerStatefulWidget {
  const BarberStaffScreen({super.key});

  @override
  ConsumerState<BarberStaffScreen> createState() => _BarberStaffScreenState();
}

class _BarberStaffScreenState extends ConsumerState<BarberStaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barberOwnerProvider.notifier).loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(barberOwnerProvider);
    final staffList = owner.staff;

    return AppScaffold(
      currentIndex: 0,
      title: 'Personel',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Personel Ekle'),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async { await ref.read(barberOwnerProvider.notifier).loadStaff(); },
              child: staffList.isEmpty
                  ? const Center(child: Text('Henüz personel eklenmemiş.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final staff = staffList[index];
                        return _StaffCard(
                          staff: staff,
                          onEdit: () => _showForm(context, staff: staff),
                          onDelete: () => _delete(context, staff.id),
                          onAssignServices: () => _showAssignServices(context, staff),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {OwnerStaff? staff}) async {
    final result = await showDialog<_StaffFormResult>(
      context: context,
      builder: (context) => _StaffFormDialog(staff: staff),
    );
    if (result == null) return;

    final state = ref.read(barberOwnerProvider);
    final success = staff == null
        ? await ref.read(barberOwnerProvider.notifier).createStaff(
            fullName: result.fullName,
            expertise: result.expertise,
            bio: result.bio,
          )
        : await ref.read(barberOwnerProvider.notifier).updateStaff(
            id: staff.id,
            fullName: result.fullName,
            expertise: result.expertise,
            bio: result.bio,
          );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? staff == null
                  ? 'Personel eklendi.'
                  : 'Personel güncellendi.'
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
        title: const Text('Personeli Sil'),
        content: const Text('Bu personeli silmek istediğinize emin misiniz?'),
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
    final success = await ref.read(barberOwnerProvider.notifier).deleteStaff(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Personel silindi.' : 'Hata: ${state.errorMessage}')),
      );
    }
  }

  Future<void> _showAssignServices(BuildContext context, OwnerStaff staff) async {
    final state = ref.read(barberOwnerProvider);
    if (state.services.isEmpty) {
      await ref.read(barberOwnerProvider.notifier).loadServices();
    }

    if (!context.mounted) return;

    final services = state.services;
    final selectedIds = staff.services.map((s) => s.id).toSet();

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _AssignServicesDialog(
        services: services,
        selectedIds: selectedIds,
      ),
    );

    if (result == null) return;
    final success = await ref.read(barberOwnerProvider.notifier).assignStaffServices(staff.id, result.toList());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Hizmetler atandı.' : 'Hata: ${state.errorMessage}')),
      );
    }
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onAssignServices,
  });

  final OwnerStaff staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssignServices;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cardBackgroundLight,
                  backgroundImage: staff.avatarUrl?.isNotEmpty == true
                      ? NetworkImage(staff.avatarUrl!)
                      : null,
                  child: staff.avatarUrl?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person, color: AppColors.primaryGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (staff.expertise?.isNotEmpty == true)
                        Text(staff.expertise!, style: AppTextStyles.caption),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.primaryGold),
                          Text(' ${staff.averageRating} (${staff.reviewCount} değerlendirme)',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                      case 'services':
                        onAssignServices();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(value: 'services', child: Text('Hizmetleri Düzenle')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            if (staff.services.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: staff.services.map((s) {
                  return Chip(
                    label: Text(s.name, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.cardBackgroundLight,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffFormResult {
  final String fullName;
  final String? expertise;
  final String? bio;

  _StaffFormResult({
    required this.fullName,
    this.expertise,
    this.bio,
  });
}

class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog({this.staff});

  final OwnerStaff? staff;

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _expertiseController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.fullName ?? '');
    _expertiseController = TextEditingController(text: widget.staff?.expertise ?? '');
    _bioController = TextEditingController(text: widget.staff?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expertiseController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(widget.staff == null ? 'Yeni Personel' : 'Personeli Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            TextField(
              controller: _expertiseController,
              decoration: const InputDecoration(labelText: 'Uzmanlık (isteğe bağlı)'),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Biyografi (isteğe bağlı)'),
              maxLines: 3,
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
            if (name.isEmpty) return;
            Navigator.pop(context, _StaffFormResult(
              fullName: name,
              expertise: _expertiseController.text.trim().isEmpty ? null : _expertiseController.text.trim(),
              bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            ));
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _AssignServicesDialog extends StatefulWidget {
  const _AssignServicesDialog({
    required this.services,
    required this.selectedIds,
  });

  final List<OwnerService> services;
  final Set<String> selectedIds;

  @override
  State<_AssignServicesDialog> createState() => _AssignServicesDialogState();
}

class _AssignServicesDialogState extends State<_AssignServicesDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('Hizmetleri Düzenle'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.services.length,
          itemBuilder: (context, index) {
            final service = widget.services[index];
            return CheckboxListTile(
              title: Text(service.name),
              subtitle: Text('${service.durationMinutes} dk • ₺${service.price}'),
              value: _selected.contains(service.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(service.id);
                  } else {
                    _selected.remove(service.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
