import 'package:flutter/material.dart';

import '../../widgets/molecules/rating_stars.dart';
import '../../widgets/molecules/section_header.dart';

class ReviewsList extends StatelessWidget {
  const ReviewsList({super.key, required this.reviews});

  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Henüz değerlendirme yok. İlk yorumu siz bırakın!'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Yorumlar'),
        ...reviews.map(
          (review) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: (review['rating'] as num).toDouble(), size: 18),
                  const SizedBox(height: 8),
                  Text(review['comment'] as String? ?? ''),
                  const SizedBox(height: 8),
                  Text(
                    review['customer_name'] as String? ?? 'Müşteri',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
