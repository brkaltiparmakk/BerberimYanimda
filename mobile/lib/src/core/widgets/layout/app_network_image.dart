import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.borderRadius = 12,
  });

  final String url;
  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url.isEmpty
          ? Container(
              height: height,
              width: width,
              color: AppColors.cardBackgroundLight,
              child: const Icon(Icons.content_cut, color: AppColors.textMuted),
            )
          : Image.network(
              url,
              height: height,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: height,
                width: width,
                color: AppColors.cardBackgroundLight,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
    );
  }
}
