import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/danger_button.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/secondary_button.dart';
import 'package:berber_yanimda/src/core/widgets/feedback/status_badge.dart';
import 'package:berber_yanimda/src/core/widgets/layout/app_network_image.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onCancel,
    this.onReview,
  });

  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(appointment.dateTime);
    final status = _status(appointment.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkImage(
                  url: appointment.barberImageUrl,
                  width: 82,
                  height: 92,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.barberName,
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        '$date · ${DateFormat('HH:mm').format(appointment.dateTime)}',
                        style: AppTextStyles.caption,
                      ),
                      Text(appointment.staffName, style: AppTextStyles.caption),
                      Text(
                        appointment.services.join(', '),
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₺${appointment.totalPrice}',
                        style: AppTextStyles.cardTitle,
                      ),
                    ],
                  ),
                ),
                StatusBadge(text: status.$1, color: status.$2),
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              DangerButton(text: 'Randevuyu İptal Et', onPressed: onCancel),
            ],
            if (onReview != null) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Yorum Yap',
                icon: Icons.rate_review_outlined,
                onPressed: onReview,
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _status(AppointmentStatus status) => switch (status) {
    AppointmentStatus.confirmed => ('Yaklaşan', AppColors.primaryGold),
    AppointmentStatus.upcoming => ('Yaklaşan', AppColors.primaryGold),
    AppointmentStatus.completed => ('Tamamlandı', AppColors.textMuted),
    AppointmentStatus.cancelled => ('İptal', AppColors.error),
    AppointmentStatus.rejected => ('Reddedildi', AppColors.error),
    AppointmentStatus.noShow => ('Gelmedi', AppColors.error),
    AppointmentStatus.pending => ('Bekliyor', AppColors.warning),
  };
}
