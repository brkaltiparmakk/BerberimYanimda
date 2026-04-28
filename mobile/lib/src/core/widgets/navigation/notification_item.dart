import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
    required this.onTap,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  final String type;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = isRead
        ? AppTextStyles.body
        : AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.borderColor : AppColors.primaryGold,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconForType(type),
              color: isRead ? AppColors.textMuted : AppColors.primaryGold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: style),
                  const SizedBox(height: 4),
                  Text(message, style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM HH:mm').format(createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'AppointmentConfirmed' => Icons.check_circle_outline,
    'AppointmentCancelled' => Icons.cancel_outlined,
    'AppointmentReminder' => Icons.access_time,
    'PaymentSuccess' => Icons.payment,
    'PaymentFailed' => Icons.error_outline,
    'Campaign' => Icons.campaign_outlined,
    _ => Icons.notifications_none,
  };
}
