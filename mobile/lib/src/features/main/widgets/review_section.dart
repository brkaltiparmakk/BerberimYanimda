import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/features/main/widgets/review_card.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewSection extends ConsumerWidget {
  const ReviewSection({super.key, required this.barberId});

  final String barberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewProvider);
    final summary = review.summary;
    final reviews = review.reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Yorumlar', style: AppTextStyles.sectionTitle),
            ),
            if (summary != null && summary.reviewCount > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.primaryGold,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.averageRating.toStringAsFixed(1)} (${summary.reviewCount})',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Text('Henuz yorum yapilmamis.', style: AppTextStyles.caption)
        else
          for (final review in reviews.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(review: review),
            ),
        if (reviews.length > 5)
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundPrimary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Tum Yorumlar', style: AppTextStyles.sectionTitle),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ReviewCard(review: reviews[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            child: Text('Tum ${reviews.length} yorumu gor'),
          ),
      ],
    );
  }
}
