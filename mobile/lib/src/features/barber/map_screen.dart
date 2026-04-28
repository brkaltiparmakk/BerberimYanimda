import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/primary_button.dart';
import 'package:berber_yanimda/src/core/widgets/navigation/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Harita',
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.backgroundSecondary,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: AppColors.textMuted, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Harita görünümü yakında geliyor',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: PrimaryButton(
              text: 'Listeye Dön',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/barbers');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
