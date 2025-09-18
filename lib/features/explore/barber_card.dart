import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/business.dart';
import '../../widgets/atoms/primary_button.dart';
import '../../widgets/molecules/rating_stars.dart';

class BarberCard extends StatelessWidget {
  const BarberCard({super.key, required this.business, required this.onTap, required this.onBookTap});

  final Business business;
  final VoidCallback onTap;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: business.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: business.coverImageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.blueGrey.shade100,
                          child: const Center(child: Icon(Icons.store_mall_directory, size: 48)),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(business.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (business.averageRating != null)
                Row(
                  children: [
                    RatingStars(rating: business.averageRating!),
                    const SizedBox(width: 8),
                    Text('${business.averageRating!.toStringAsFixed(1)} (${business.reviewCount ?? 0})'),
                  ],
                ),
              if (business.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 4),
                    Expanded(child: Text(business.address!)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(onPressed: onBookTap, label: 'Randevu Al', icon: Icons.calendar_month),
            ],
          ),
        ),
      ),
    );
  }
}
