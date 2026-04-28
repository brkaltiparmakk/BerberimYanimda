import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class RatingView extends StatelessWidget {
  const RatingView({super.key, required this.rating, this.reviewCount});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.star, color: AppColors.primaryGold, size: 15),
        ),
        const SizedBox(width: 4),
        Text(
          reviewCount == null
              ? rating.toStringAsFixed(1)
              : '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
