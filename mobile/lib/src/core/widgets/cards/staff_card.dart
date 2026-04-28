import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/layout/rating_view.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/material.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.staff,
    required this.selected,
    required this.onTap,
  });

  final Staff? staff;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = staff?.name ?? 'Farketmez';
    final expertise = staff?.expertise ?? 'En uygun personel atansın';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryGold : AppColors.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.cardBackgroundLight,
              backgroundImage: staff != null && staff!.avatarUrl.isNotEmpty
                  ? NetworkImage(staff!.avatarUrl)
                  : null,
              child: staff == null
                  ? const Icon(Icons.shuffle, color: AppColors.primaryGold)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.cardTitle),
                  Text(expertise, style: AppTextStyles.caption),
                  if (staff != null) RatingView(rating: staff!.rating),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primaryGold : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
