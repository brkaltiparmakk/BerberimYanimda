import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';

import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final data = await client.from('profiles').select<Map<String, dynamic>>().eq('id', userId).maybeSingle();
    if (data != null) {
      _nameCtrl.text = data['full_name'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('profiles').update({
      'full_name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profiliniz güncellendi.')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: ValidationBuilder(localeName: 'tr').minLength(2).build(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              PrimaryButton(onPressed: _update, label: 'Kaydet'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(supabaseClientProvider).auth.signOut();
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
