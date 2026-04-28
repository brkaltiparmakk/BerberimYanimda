import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppointmentSuccessScreen extends ConsumerWidget {
  const AppointmentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider);
    final catalog = ref.watch(catalogProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/appointments');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 94,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Randevun oluşturuldu!',
                  style: AppTextStyles.largeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${booking.lastCreatedAppointment?.barberName ?? catalog.selectedBarber?.name} - ${booking.selectedSlot?.startTime}',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SecondaryButton(
                  text: 'Takvime Ekle',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Randevularım',
                  onPressed: () => context.go('/appointments'),
                ),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
