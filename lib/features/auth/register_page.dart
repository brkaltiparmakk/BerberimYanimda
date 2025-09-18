import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ref.read(supabaseClientProvider).auth.signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            data: {'phone': _phoneCtrl.text},
          );
      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesabınız oluşturuldu. Lütfen e-posta onayınızı tamamlayın.')),
        );
        context.go('/explore');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarısız: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Hesap Oluştur', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: ValidationBuilder(localeName: 'tr').email().build(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: ValidationBuilder(localeName: 'tr').minLength(6).build(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon (opsiyonel)'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _loading ? null : _submit,
                label: _loading ? 'Kaydediliyor...' : 'Hesap Oluştur',
              ),
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Zaten hesabın var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
