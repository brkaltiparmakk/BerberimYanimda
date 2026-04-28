import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/booking/widgets/booking_shell.dart';
import 'package:berber_yanimda/src/features/booking/widgets/missing_booking_data.dart';
import 'package:berber_yanimda/src/features/booking/widgets/retry_box.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final barber = ref.read(catalogProvider).selectedBarber;
      if (barber != null && barber.services.isEmpty) {
        ref.read(catalogProvider.notifier).loadBarberDetail(barber.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final booking = ref.watch(bookingProvider);
    final barber = catalog.selectedBarber;
    if (barber == null) {
      return MissingBookingData(message: 'Önce bir berber seçmelisiniz.');
    }

    final selectedServices = booking.getSelectedServices(barber);

    return BookingShell(
      title: 'Randevu Oluştur',
      step: 1,
      errorMessage: catalog.errorMessage ?? booking.errorMessage,
      bottom: PrimaryButton(
        text: 'Devam Et',
        onPressed: selectedServices.isEmpty
            ? null
            : () => context.push('/booking/staff'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const Text('Hizmet Seçimi', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Almak istediğiniz hizmetleri seçin',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          if (catalog.isBusy && barber.services.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (barber.services.isEmpty)
            RetryBox(
              message: 'Hizmetler yüklenemedi.',
              onRetry: () =>
                  ref.read(catalogProvider.notifier).loadBarberDetail(barber.id),
            )
          else
            for (final service in barber.services)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ServiceCard(
                  service: service,
                  selected: booking.selectedServiceIds.contains(service.id),
                  onTap: () =>
                      ref.read(bookingProvider.notifier).toggleService(service.id),
                ),
              ),
          const SizedBox(height: 12),
          PriceSummaryCard(
            duration: booking.getTotalDuration(barber),
            price: booking.getTotalPrice(barber),
          ),
        ],
      ),
    );
  }
}
