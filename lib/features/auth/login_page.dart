import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      if (mounted) context.go('/explore');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş başarısız: ${e.message}')),
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
              Text('Kayıt Ol / Giriş Yap', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _loading ? null : _submit,
                label: _loading ? 'Yükleniyor...' : 'Giriş Yap',
              ),
              TextButton(
                onPressed: () => context.go('/auth/register'),
                child: const Text('Hesabın yok mu? Hesap Oluştur'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        await ref.read(supabaseClientProvider).auth.signInWithOAuth(Provider.google);
                      },
                icon: const Icon(Icons.login),
                label: const Text('Sosyal Medya ile Kaydol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
