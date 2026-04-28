import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/booking/widgets/booking_shell.dart';
import 'package:berber_yanimda/src/features/booking/widgets/missing_booking_data.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StaffSelectionScreen extends ConsumerWidget {
  const StaffSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final booking = ref.watch(bookingProvider);
    final barber = catalog.selectedBarber;
    if (barber == null) {
      return MissingBookingData(message: 'Önce bir berber seçmelisiniz.');
    }

    return BookingShell(
      title: 'Personel Seçimi',
      step: 2,
      errorMessage: booking.errorMessage,
      bottom: PrimaryButton(
        text: booking.isBusy ? 'Saatler yükleniyor...' : 'Devam Et',
        onPressed: booking.isBusy
            ? null
            : () async {
                await ref.read(bookingProvider.notifier).loadSlots();
                if (context.mounted) context.push('/booking/time');
              },
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const Text(
            'Hizmetinizi kimin yapmasını istersiniz?',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          StaffCard(
            staff: null,
            selected: booking.selectedStaff == null,
            onTap: () => ref.read(bookingProvider.notifier).selectStaff(null),
          ),
          const SizedBox(height: 10),
          for (final staff in barber.staff)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StaffCard(
                staff: staff,
                selected: booking.selectedStaff?.id == staff.id,
                onTap: () => ref.read(bookingProvider.notifier).selectStaff(staff),
              ),
            ),
        ],
      ),
    );
  }
}
