import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RoundIcon extends StatelessWidget {
  const RoundIcon({super.key, required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundPrimary.withValues(alpha: 0.74),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        tooltip: tooltip ?? '',
      ),
    );
  }
}
