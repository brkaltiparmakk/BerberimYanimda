import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/main/widgets/inline_error.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final l10n = AppLocalizations.of(context)!;
    final items = [
      if (auth.isBarber)
        (
          Icons.dashboard_outlined,
          l10n.dashboard,
          () => context.go('/barber/dashboard'),
        ),
      (Icons.favorite_border, l10n.myFavorites, () => context.go('/favorites')),
      (
        Icons.notifications_none,
        l10n.notifications,
        () => context.push('/notifications'),
      ),
      (
        Icons.lock_outline,
        l10n.changePassword,
        () => _showChangePasswordDialog(context, ref),
      ),
      (
        Icons.download_outlined,
        l10n.exportData,
        () => _exportData(context, ref),
      ),
      (Icons.settings_outlined, l10n.settings, () => context.push('/settings')),
      (Icons.help_outline, l10n.support, () => context.push('/support')),
      (
        Icons.delete_outline,
        l10n.deleteAccount,
        () => _showDeleteAccountDialog(context, ref),
      ),
      (
        Icons.logout,
        l10n.logout,
        () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      ),
    ];
    return AppScaffold(
      currentIndex: 4,
      title: l10n.profile,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.cardBackgroundLight,
                  backgroundImage: profile?.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(profile!.profileImageUrl!)
                      : null,
                  child: profile?.profileImageUrl?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person, color: AppColors.primaryGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? auth.userName,
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        profile?.phoneNumber ?? '',
                        style: AppTextStyles.caption,
                      ),
                      if (profile?.email?.isNotEmpty == true)
                        Text(profile!.email!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      tooltip: l10n.editProfile,
                      onPressed: () => context.push('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.profilePhoto,
                      onPressed: () => _pickProfileImage(ref),
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            InlineError(message: auth.errorMessage!, onRetry: null),
          ],
          const SizedBox(height: 16),
          for (final item in items)
            ProfileMenuItem(
              icon: item.$1,
              title: item.$2,
              onTap: item.$3,
              isDanger:
                  item.$1 == Icons.logout || item.$1 == Icons.delete_outline,
            ),
        ],
      ),
    );
  }
}

Future<void> _showChangePasswordDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  try {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.changePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentPassword,
                hintText: l10n.currentPassword,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: newPassword,
                hintText: l10n.newPassword,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: confirmPassword,
                hintText: l10n.confirmNewPassword,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (newPassword.text != confirmPassword.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.passwordsDontMatch)),
                  );
                  return;
                }
                final success = await ref
                    .read(authProvider.notifier)
                    .changePassword(currentPassword.text, newPassword.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.passwordChanged)),
                  );
                }
              },
              child: Text(l10n.edit),
            ),
          ],
        );
      },
    );
  } finally {
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
  }
}

Future<void> _showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final password = TextEditingController();

  try {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.deleteAccountWarning,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: password,
                hintText: l10n.enterYourPassword,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final success = await ref
                    .read(authProvider.notifier)
                    .deleteAccount(password.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.deleteAccount),
            ),
          ],
        );
      },
    );
  } finally {
    password.dispose();
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.preparingData)));
  final success = await ref.read(authProvider.notifier).exportUserData();
  if (!success && context.mounted) {
    final error = ref.read(authProvider).errorMessage ?? l10n.dataDownloadFailed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }
}

Future<void> _pickProfileImage(WidgetRef ref) async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 82,
    maxWidth: 1200,
  );
  if (image != null) {
    await ref.read(authProvider.notifier).uploadProfileImage(image.path);
  }
}
