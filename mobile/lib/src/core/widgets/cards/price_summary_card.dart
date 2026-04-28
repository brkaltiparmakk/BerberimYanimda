import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.duration,
    required this.price,
    this.discount = 0,
  });

  final int duration;
  final int price;
  final int discount;

  @override
  Widget build(BuildContext context) {
    final total = price - discount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Toplam Süre', value: '$duration dk'),
          if (discount > 0)
            _SummaryRow(
              label: 'İndirim',
              value: '-₺$discount',
              highlighted: true,
            ),
          _SummaryRow(
            label: 'Toplam Tutar',
            value: '₺$total',
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(
                color: highlighted
                    ? AppColors.primaryGold
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
