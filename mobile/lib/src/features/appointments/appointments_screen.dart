import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/features/booking/widgets/error_box.dart';
import 'package:berber_yanimda/src/features/booking/widgets/retry_box.dart';
import 'package:berber_yanimda/src/features/booking/widgets/status_tabs.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(appointmentProvider.notifier).loadAppointments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = ref.watch(appointmentProvider);
    final appointments = appt.filtered;
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      currentIndex: 2,
      title: l10n.appointments,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const StatusTabs(),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            RetryBox(
              message: appt.errorMessage ?? l10n.noAppointmentsInCategory,
              loading: appt.isBusy,
              onRetry: () => ref.read(appointmentProvider.notifier).loadAppointments(),
            )
          else ...[
            if (appt.errorMessage != null) ...[
              ErrorBox(message: appt.errorMessage!),
              const SizedBox(height: 12),
            ],
            for (final appointment in appointments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppointmentCard(
                  appointment: appointment,
                  onTap: () => context.push(
                    '/appointment/${appointment.id}',
                    extra: appointment,
                  ),
                  onCancel: appointment.status == AppointmentStatus.pending ||
                          appointment.status == AppointmentStatus.confirmed
                      ? () => ref
                          .read(appointmentProvider.notifier)
                          .cancelAppointment(appointment.id)
                      : null,
                  onReview: appointment.status == AppointmentStatus.completed
                      ? () => context.push('/review', extra: appointment)
                      : null,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
