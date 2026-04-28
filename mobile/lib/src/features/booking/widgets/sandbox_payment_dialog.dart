import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class SandboxPaymentDialog extends StatelessWidget {
  const SandboxPaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('Sandbox Ödeme', style: AppTextStyles.sectionTitle),
      content: const Text(
        'Bu bir test ödeme ekranıdır. Gerçek para çekilmeyecektir.',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Başarısız', style: TextStyle(color: AppColors.error)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Başarılı'),
        ),
      ],
    );
  }
}
