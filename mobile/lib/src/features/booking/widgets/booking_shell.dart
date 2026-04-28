import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/features/booking/widgets/error_box.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingShell extends StatelessWidget {
  const BookingShell({
    super.key,
    required this.title,
    required this.step,
    required this.child,
    required this.bottom,
    this.errorMessage,
  });

  final String title;
  final int step;
  final Widget child;
  final Widget bottom;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _popOrGo(context, _bookingBackFallback(step)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: List.generate(4, (index) {
                  final active = index + 1 <= step;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryGold
                            : AppColors.borderColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: ErrorBox(message: errorMessage!),
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: bottom,
      ),
    );
  }
}

void _popOrGo(BuildContext context, String fallbackRoute) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}

String _bookingBackFallback(int step) {
  return switch (step) {
    1 => '/barbers',
    2 => '/booking/services',
    3 => '/booking/staff',
    4 => '/booking/time',
    _ => '/barbers',
  };
}
