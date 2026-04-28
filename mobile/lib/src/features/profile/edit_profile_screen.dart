import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/primary_button.dart';
import 'package:berber_yanimda/src/core/widgets/inputs/app_text_field.dart';
import 'package:berber_yanimda/src/core/widgets/navigation/custom_app_bar.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _name = TextEditingController(text: profile?.fullName ?? '');
    _phone = TextEditingController(text: profile?.phoneNumber ?? '');
    _email = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil Düzenle',
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundImage:
                    state.profile?.profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(state.profile!.profileImageUrl!)
                    : null,
                child: state.profile?.profileImageUrl?.isNotEmpty != true
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _name,
              hintText: 'Ad Soyad',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              hintText: 'Telefon',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              hintText: 'E-posta',
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: state.isBusy ? 'Kaydediliyor...' : 'Kaydet',
              onPressed: state.isBusy
                  ? null
                  : () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .updateProfile(
                            fullName: _name.text.trim(),
                            email: _email.text.trim().isEmpty
                                ? null
                                : _email.text.trim(),
                          );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil güncellendi.')),
                        );
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile');
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
