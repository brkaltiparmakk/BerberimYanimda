import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusTabs extends ConsumerWidget {
  const StatusTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(appointmentProvider).filter;
    final l10n = AppLocalizations.of(context)!;

    Widget tab(String label, AppointmentFilter value) {
      final isActive = filter == value;
      return GestureDetector(
        onTap: () => ref.read(appointmentProvider.notifier).setFilter(value),
        child: StatusBadge(
          text: label,
          color: isActive ? AppColors.primaryGold : AppColors.textMuted,
        ),
      );
    }

    return Row(
      children: [
        tab(l10n.upcoming, AppointmentFilter.upcoming),
        const SizedBox(width: 8),
        tab(l10n.past, AppointmentFilter.past),
        const SizedBox(width: 8),
        tab(l10n.cancelled, AppointmentFilter.cancelled),
      ],
    );
  }
}
