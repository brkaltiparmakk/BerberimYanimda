import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CouponInput extends ConsumerStatefulWidget {
  const CouponInput({super.key});

  @override
  ConsumerState<CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends ConsumerState<CouponInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupon = ref.watch(couponProvider);
    final booking = ref.watch(bookingProvider);
    final catalog = ref.watch(catalogProvider);
    final hasCoupon = coupon.result != null && coupon.result!.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _controller,
                hintText: 'Kupon kodu girin',
                icon: Icons.local_offer_outlined,
                enabled: !hasCoupon,
              ),
            ),
            const SizedBox(width: 8),
            if (hasCoupon)
              TextButton(
                onPressed: () {
                  _controller.clear();
                  ref.read(couponProvider.notifier).clear();
                },
                child: const Text('Kaldir'),
              )
            else
              TextButton(
                onPressed: coupon.isBusy
                    ? null
                    : () async {
                        final code = _controller.text.trim();
                        if (code.isEmpty) return;
                        final barber = catalog.selectedBarber;
                        final totalPrice = barber != null ? booking.getTotalPrice(barber) : 0;
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref.read(couponProvider.notifier).validate(code, totalPrice);
                        if (success && mounted) {
                          final result = ref.read(couponProvider).result;
                          if (result != null && result.isValid) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Kupon uygulandi! Indirim: TRY ${result.discountAmount}')),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text(result?.message ?? 'Gecersiz kupon')),
                            );
                          }
                        }
                      },
                child: const Text('Uygula'),
              ),
          ],
        ),
      ],
    );
  }
}
