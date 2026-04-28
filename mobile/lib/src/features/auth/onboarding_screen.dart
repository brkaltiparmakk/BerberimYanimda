import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.place_outlined,
        'Yakındaki berberleri keşfet',
        'Konumuna en yakın ve en uygun berberleri listele.',
      ),
      (
        Icons.calendar_month_outlined,
        'Kolayca randevu al',
        'Hizmet, personel, tarih ve saat seçimini hızlıca tamamla.',
      ),
      (
        Icons.verified_user_outlined,
        'Güvenli deneyim',
        'Randevularını ve ödeme tercihini güvenle yönet.',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGold),
                          ),
                          child: Icon(
                            item.$1,
                            size: 84,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          item.$2,
                          style: AppTextStyles.largeTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$3,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              PrimaryButton(
                text: 'Başla',
                icon: Icons.arrow_forward,
                onPressed: () => context.go('/login'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Uygulamayı gez'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
