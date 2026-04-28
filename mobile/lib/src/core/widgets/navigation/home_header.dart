import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    this.location,
    this.onNotificationTap,
    this.onProfileTap,
    this.profileImageUrl,
    this.unreadCount = 0,
  });

  final String userName;
  final String? location;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helloUser(userName),
                style: AppTextStyles.screenTitle,
              ),
              if (location != null) ...[
                const SizedBox(height: 4),
                Text(
                  location!,
                  style: AppTextStyles.body,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.notifications,
          onPressed: onNotificationTap,
          icon: Badge.count(
            count: unreadCount,
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications_none),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            backgroundColor: AppColors.cardBackgroundLight,
            backgroundImage: profileImageUrl?.isNotEmpty == true
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageUrl?.isNotEmpty != true
                ? const Icon(Icons.person)
                : null,
          ),
        ),
      ],
    );
  }
}
