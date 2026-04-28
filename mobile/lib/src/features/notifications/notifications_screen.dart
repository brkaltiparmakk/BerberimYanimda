import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/main/widgets/state_message.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(notificationProvider.notifier).loadNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notif = ref.watch(notificationProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: notif.notifications.any((item) => !item.isRead)
                ? () => ref.read(notificationProvider.notifier).markAllRead()
                : null,
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: notif.notifications.isEmpty ? 1 : notif.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (notif.notifications.isEmpty) {
            return StateMessage(
              message: notif.errorMessage ?? l10n.noNotifications,
              loading: notif.isBusy,
              onRetry: () => ref.read(notificationProvider.notifier).loadNotifications(),
            );
          }

          final item = notif.notifications[index];
          return NotificationItem(
            title: item.title,
            message: item.message,
            createdAt: item.createdAt,
            type: item.type,
            isRead: item.isRead,
            onTap: item.isRead
                ? null
                : () =>
                    ref.read(notificationProvider.notifier).markRead(item.id),
          );
        },
      ),
    );
  }
}
