import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/small_button.dart';
import 'package:berber_yanimda/src/core/widgets/layout/app_network_image.dart';
import 'package:berber_yanimda/src/core/widgets/layout/rating_view.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/material.dart';

class BarberCard extends StatelessWidget {
  const BarberCard({
    super.key,
    required this.barber,
    required this.onTap,
    required this.onFavorite,
    required this.onBook,
  });

  final Barber barber;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${barber.name}, Puan: ${barber.rating.toStringAsFixed(1)}, ${barber.district}',
      button: true,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(url: barber.imageUrl, width: 92, height: 110),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          barber.name,
                          style: AppTextStyles.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Favori',
                        onPressed: onFavorite,
                        icon: Icon(
                          barber.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: barber.isFavorite
                              ? AppColors.primaryGold
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  RatingView(
                    rating: barber.rating,
                    reviewCount: barber.reviewCount,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${barber.district}, ${barber.city} · ${barber.distanceKm.toStringAsFixed(1)} km',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Başlangıç ₺${barber.startingPrice}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (barber.isAvailableToday) ...[
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Bugün müsait',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ] else ...[
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.cancel,
                            color: AppColors.error,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Bugün kapalı',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                      SmallButton(
                        text: 'Randevu Al',
                        onPressed: onBook,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
