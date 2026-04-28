import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/features/booking/widgets/error_box.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorum Yap'),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appointment.barberName,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'dd MMM yyyy · HH:mm',
                    ).format(widget.appointment.dateTime),
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    widget.appointment.staffName,
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    widget.appointment.services.join(', '),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Puanınız', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  tooltip: '${index + 1} yıldız',
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.primaryGold,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yorumunuz (Opsiyonel)',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _comment,
              hintText: 'Deneyiminizi paylaşın...',
              icon: Icons.comment_outlined,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              ErrorBox(message: state.errorMessage!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: PrimaryButton(
          text: state.isBusy ? 'Gönderiliyor...' : 'Yorum Gönder',
          onPressed: state.isBusy
              ? null
              : () async {
                  final success = await ref
                      .read(reviewProvider.notifier)
                      .createReview(
                        appointmentId: widget.appointment.id,
                        rating: _rating,
                        comment: _comment.text.trim().isEmpty
                            ? null
                            : _comment.text.trim(),
                      );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Yorumunuz alındı. Onaydan sonra yayınlanacaktır.',
                        ),
                      ),
                    );
                    context.pop();
                  }
                },
        ),
      ),
    );
  }
}
