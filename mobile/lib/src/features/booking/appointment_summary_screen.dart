import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/booking/widgets/booking_shell.dart';
import 'package:berber_yanimda/src/features/booking/widgets/summary_row.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AppointmentSummaryScreen extends ConsumerWidget {
  const AppointmentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final booking = ref.watch(bookingProvider);
    final barber = catalog.selectedBarber;
    final selectedServices = barber != null ? booking.getSelectedServices(barber) : [];

    return BookingShell(
      title: 'Randevu Özeti',
      step: 4,
      errorMessage: booking.errorMessage,
      bottom: PrimaryButton(
        text: 'Devam Et',
        onPressed: booking.selectedSlot == null
            ? null
            : () => context.push('/payment'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          SummaryRow(
            label: 'Berber',
            value: barber?.name ?? '-',
          ),
          SummaryRow(
            label: 'Hizmetler',
            value: selectedServices
                .map((service) => service.name)
                .join(', '),
          ),
          SummaryRow(
            label: 'Personel',
            value: booking.selectedStaff?.name ?? 'Farketmez',
          ),
          SummaryRow(
            label: 'Tarih',
            value: booking.selectedDate != null
                ? DateFormat('dd MMM yyyy').format(booking.selectedDate!)
                : '-',
          ),
          SummaryRow(
            label: 'Saat',
            value: booking.selectedSlot?.startTime ?? '-',
          ),
          SummaryRow(
            label: 'Toplam',
            value: 'TRY ${barber != null ? booking.getTotalPrice(barber) : 0}',
            highlighted: true,
          ),
        ],
      ),
    );
  }
}
