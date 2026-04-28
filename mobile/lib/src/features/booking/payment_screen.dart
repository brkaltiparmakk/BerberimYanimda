import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/booking/widgets/coupon_input.dart';
import 'package:berber_yanimda/src/features/booking/widgets/error_box.dart';
import 'package:berber_yanimda/src/features/booking/widgets/missing_booking_data.dart';
import 'package:berber_yanimda/src/features/booking/widgets/sandbox_payment_dialog.dart';
import 'package:berber_yanimda/src/features/booking/widgets/summary_row.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final booking = ref.watch(bookingProvider);
    final coupon = ref.watch(couponProvider);
    final barber = catalog.selectedBarber;
    final selectedServices = barber != null ? booking.getSelectedServices(barber) : [];

    if (barber == null ||
        booking.selectedSlot == null ||
        selectedServices.isEmpty) {
      return const MissingBookingData(message: 'Randevu bilgileri eksik.');
    }

    final totalPrice = booking.getTotalPrice(barber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            const SectionHeader(title: 'Özet'),
            SummaryRow(
              label: selectedServices
                  .map((service) => service.name)
                  .join(', '),
              value: 'TRY $totalPrice',
            ),
            if (booking.errorMessage != null) ...[
              const SizedBox(height: 12),
              ErrorBox(message: booking.errorMessage!),
            ],
            const SizedBox(height: 18),
            const SectionHeader(title: 'Ödeme Yöntemi'),
            PaymentMethodCard(
              title: 'Berberde Öde',
              subtitle: 'Nakit veya işletmenin kabul ettiği yöntem',
              selected: !booking.isOnlinePayment,
              icon: Icons.storefront_outlined,
              onTap: () => ref.read(bookingProvider.notifier).setPaymentMethod(false),
            ),
            const SizedBox(height: 8),
            PaymentMethodCard(
              title: 'Online Ödeme (Sandbox)',
              subtitle: 'Kredi/banka kartı ile güvenli ödeme',
              selected: booking.isOnlinePayment,
              icon: Icons.credit_card_outlined,
              onTap: () => ref.read(bookingProvider.notifier).setPaymentMethod(true),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Kupon Kodu'),
            CouponInput(),
            const SizedBox(height: 18),
            if (coupon.result != null && coupon.result!.isValid) ...[
              SummaryRow(
                label: 'İndirim (${coupon.code})',
                value: '-TRY ${coupon.result!.discountAmount}',
                highlighted: false,
              ),
              const SizedBox(height: 8),
            ],
            SummaryRow(
              label: 'Toplam Tutar',
              value: 'TRY ${coupon.result?.finalAmount ?? totalPrice}',
              highlighted: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: PrimaryButton(
          text: booking.isBusy ? 'Onaylanıyor...' : 'Randevuyu Onayla',
          onPressed: booking.isBusy
              ? null
              : () async {
                  if (booking.isOnlinePayment) {
                    final success = await ref.read(bookingProvider.notifier).createPayAtBarberAppointment();
                    if (!success || !context.mounted) return;

                    final sessionSuccess = await ref.read(bookingProvider.notifier).createOnlinePaymentSession();
                    if (!sessionSuccess || !context.mounted) return;

                    final paymentSuccess = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const SandboxPaymentDialog(),
                    );

                    if (paymentSuccess == null || !context.mounted) return;

                    final completeSuccess = await ref.read(bookingProvider.notifier).sandboxCompletePayment(paymentSuccess);
                    if (completeSuccess && context.mounted) {
                      context.go('/success');
                    }
                  } else {
                    final success = await ref.read(bookingProvider.notifier).createPayAtBarberAppointment();
                    if (success && context.mounted) context.go('/success');
                  }
                },
        ),
      ),
    );
  }
}
