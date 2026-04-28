import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/booking/widgets/booking_shell.dart';
import 'package:berber_yanimda/src/features/booking/widgets/retry_box.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/core/widgets/cards/date_selector.dart';
import 'package:berber_yanimda/src/core/widgets/cards/time_slot_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DateTimeSelectionScreen extends ConsumerWidget {
  const DateTimeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider);
    final today = DateTime.now();
    final dates = List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: index + 1)),
    );
    return BookingShell(
      title: 'Tarih ve Saat',
      step: 3,
      errorMessage: booking.errorMessage,
      bottom: PrimaryButton(
        text: 'Devam Et',
        onPressed: booking.selectedSlot == null
            ? null
            : () => context.push('/booking/summary'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const Text('Uygun tarih ve saati seçin', style: AppTextStyles.body),
          const SizedBox(height: 16),
          DateSelector(
            dates: dates,
            selectedDate: booking.selectedDate ?? today.add(const Duration(days: 1)),
            onDateSelected: (date) =>
                ref.read(bookingProvider.notifier).selectDate(date),
          ),
          const SizedBox(height: 20),
          if (booking.isBusy)
            const Center(child: CircularProgressIndicator())
          else if (booking.slots.isEmpty)
            RetryBox(
              message: 'Bu seçim için uygun saat bulunamadı.',
              onRetry: () => ref.read(bookingProvider.notifier).loadSlots(),
            )
          else
            TimeSlotGrid(
              slots: booking.slots,
              selectedSlot: booking.selectedSlot,
              onSlotSelected: (slot) =>
                  ref.read(bookingProvider.notifier).selectSlot(slot),
            ),
        ],
      ),
    );
  }
}
