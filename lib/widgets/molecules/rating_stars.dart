import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemSize: size,
      unratedColor: Colors.grey.shade300,
      itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
    );
  }
}
