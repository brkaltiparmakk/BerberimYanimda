import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/auth_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final fullName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    return AuthShell(
      title: l10n.register,
      subtitle: l10n.unverifiedPhone,
      errorMessage: state.errorMessage,
      children: [
        AppTextField(
          controller: fullName,
          hintText: l10n.fullName,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: phone,
          hintText: l10n.phone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: email,
          hintText: l10n.email,
          icon: Icons.mail_outline,
        ),
        const SizedBox(height: 12),
        PasswordTextField(
          controller: password,
          hintText: l10n.password,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: state.isBusy ? l10n.registering : l10n.register,
          onPressed: state.isBusy
              ? null
              : () async {
                  final success = await ref
                      .read(authProvider.notifier)
                      .register(
                        fullName.text.trim(),
                        phone.text.trim(),
                        email.text.trim(),
                        password.text,
                      );
                  if (success && context.mounted) {
                    context.go(
                      '/otp',
                      extra: {
                        'phone': phone.text.trim(),
                        'password': password.text,
                      },
                    );
                  }
                },
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }
}
