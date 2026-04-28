import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == 0;
          return Chip(
            label: Text(items[index]),
            backgroundColor: active
                ? AppColors.primaryGold
                : AppColors.cardBackground,
            labelStyle: TextStyle(
              color: active
                  ? AppColors.backgroundPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: active ? AppColors.primaryGold : AppColors.borderColor,
            ),
          );
        },
      ),
    );
  }
}
