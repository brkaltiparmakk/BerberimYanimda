import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    return AuthShell(
      title: l10n.welcome,
      subtitle: l10n.appSubtitle,
      errorMessage: state.errorMessage,
      children: [
        AppTextField(
          controller: phone,
          hintText: l10n.phoneNumber,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        PasswordTextField(
          controller: password,
          hintText: l10n.password,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: state.isBusy ? l10n.loggingIn : l10n.login,
          onPressed: state.isBusy
              ? null
              : () async {
                  final success = await ref
                      .read(authProvider.notifier)
                      .login(phone.text.trim(), password.text);
                  if (success && context.mounted) context.go('/home');
                },
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(l10n.dontHaveAccount),
        ),
      ],
    );
  }
}
