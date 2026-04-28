import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/navigation/custom_app_bar.dart';
import 'package:berber_yanimda/src/features/profile/privacy_policy_screen.dart';
import 'package:berber_yanimda/src/features/profile/terms_of_service_screen.dart';
import 'package:berber_yanimda/src/features/profile/kvkk_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.notifications_none, 'Bildirim Ayarları', () => _openAppSettings(context)),
      (Icons.location_on_outlined, 'Konum İzni', () => _openAppSettings(context)),
      (Icons.language_outlined, 'Dil', () => _showLanguageDialog(context)),
      (Icons.dark_mode_outlined, 'Tema', () => _showThemeDialog(context)),
      (Icons.privacy_tip_outlined, 'Gizlilik Politikası', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
      }),
      (Icons.description_outlined, 'Kullanım Şartları', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
      }),
      (Icons.verified_user_outlined, 'KVKK Aydınlatma Metni', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const KvkkInfoScreen()));
      }),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ayarlar',
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.$1, color: AppColors.textSecondary),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: item.$3,
            ),
          const SizedBox(height: 16),
          Text(
            'Uygulama Sürümü 1.0.0',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Future<void> _openAppSettings(BuildContext context) async {
  final uri = Uri.parse('app-settings:');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayarlar açılamadı.')),
    );
  }
}

Future<void> _showLanguageDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Dil Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇹🇷'),
              title: const Text('Türkçe'),
              trailing: const Icon(Icons.check, color: AppColors.primaryGold),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dil: Türkçe seçildi.')),
                );
              },
            ),
            ListTile(
              leading: const Text('🇬🇧'),
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dil: English seçildi.')),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showThemeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tema Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Açık Tema'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Açık tema seçildi (yakında).')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Koyu Tema'),
              trailing: const Icon(Icons.check, color: AppColors.primaryGold),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Koyu tema aktif.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: const Text('Sistem Teması'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sistem teması seçildi (yakında).')),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
