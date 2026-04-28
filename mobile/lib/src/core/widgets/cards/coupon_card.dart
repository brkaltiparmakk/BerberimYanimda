import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.code,
    required this.description,
    required this.isApplied,
    required this.onTap,
  });

  final String code;
  final String? description;
  final bool isApplied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApplied ? AppColors.primaryGold : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: isApplied ? AppColors.primaryGold : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null)
                    Text(description!, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (isApplied)
              const Icon(Icons.check_circle, color: AppColors.primaryGold)
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
