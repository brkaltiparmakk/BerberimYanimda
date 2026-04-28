import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/auth_shell.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber, this.password});

  final String phoneNumber;
  final String? password;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final code = TextEditingController(text: '123456');

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    return AuthShell(
      title: l10n.verify,
      subtitle: l10n.unverifiedPhone,
      errorMessage: state.errorMessage,
      children: [
        OtpInput(
          length: 6,
          onCompleted: (value) => code.text = value,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: state.isBusy ? l10n.verifying : l10n.verify,
          onPressed: state.isBusy
              ? null
              : () async {
                  final success = await ref
                      .read(authProvider.notifier)
                      .verifyOtp(
                        widget.phoneNumber,
                        code.text.trim(),
                        password: widget.password,
                      );
                  if (!context.mounted) return;
                  if (success && ref.read(authProvider).isLoggedIn) {
                    context.go('/home');
                  } else if (success) {
                    context.go('/login');
                  }
                },
        ),
      ],
    );
  }
}
