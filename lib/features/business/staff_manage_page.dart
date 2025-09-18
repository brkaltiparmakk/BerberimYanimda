import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/staff_member.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class StaffManagePage extends ConsumerStatefulWidget {
  const StaffManagePage({super.key});

  @override
  ConsumerState<StaffManagePage> createState() => _StaffManagePageState();
}

class _StaffManagePageState extends ConsumerState<StaffManagePage> {
  List<StaffMember> _staff = const [];
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
      setState(() => _loading = false);
      return;
    }
    final staff = await ref.read(businessRepositoryProvider).fetchStaff(businessId);
    setState(() {
      _businessId = businessId;
      _staff = staff;
      _loading = false;
    });
  }

  Future<void> _toggleActive(StaffMember member, bool value) async {
    await ref.read(supabaseClientProvider).from('staff').update({'active': value}).eq('id', member.id);
    _load();
  }

  Future<void> _addStaff() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personel Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad Soyad')),
            const SizedBox(height: 12),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Rol')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              await ref.read(supabaseClientProvider).from('staff').insert({
                'business_id': _businessId,
                'full_name': nameCtrl.text,
                'role': roleCtrl.text,
                'active': true,
              });
              if (mounted) {
                Navigator.of(context).pop();
                _load();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.group, message: 'İşletme bulunamadı.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Personel Yönetimi'), actions: [
        IconButton(onPressed: _addStaff, icon: const Icon(Icons.person_add)),
      ]),
      body: _staff.isEmpty
          ? const EmptyState(icon: Icons.group, message: 'Henüz personel eklenmedi.')
          : ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (context, index) {
                final member = _staff[index];
                return SwitchListTile(
                  title: Text(member.fullName),
                  subtitle: Text(member.role),
                  value: member.active,
                  onChanged: (value) => _toggleActive(member, value),
                );
              },
            ),
    );
  }
}
