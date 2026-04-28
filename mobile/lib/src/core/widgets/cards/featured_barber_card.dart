import 'dart:ui';

import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/material.dart';

class FeaturedBarberCard extends StatelessWidget {
  const FeaturedBarberCard({
    super.key,
    required this.barber,
    required this.onTap,
  });

  final Barber barber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${barber.name}, Puan: ${barber.rating.toStringAsFixed(1)}, ${barber.district}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor),
          color: AppColors.cardBackground,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (barber.imageUrl.isNotEmpty)
                Image.network(
                  barber.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.cardBackground,
                  ),
                )
              else
                Container(color: AppColors.cardBackground),

              // Gradient overlay: transparent top → dark bottom
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xD9000000), // rgba(0,0,0,0.85)
                    ],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "ÖNE ÇIKAN" badge — top left
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ÖNE ÇIKAN',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Barber name
                    Text(
                      barber.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating + review count + district + distance
                    Row(
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.star_rounded,
                            color: AppColors.primaryGold,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          barber.rating.toStringAsFixed(1),
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${barber.reviewCount})',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          barber.district,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${barber.distanceKm.toStringAsFixed(1)} km',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
