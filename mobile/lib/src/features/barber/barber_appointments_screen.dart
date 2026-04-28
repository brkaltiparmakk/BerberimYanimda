import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BarberAppointmentsScreen extends ConsumerStatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  ConsumerState<BarberAppointmentsScreen> createState() => _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState extends ConsumerState<BarberAppointmentsScreen> {
  DateTime? _filterDate;
  AppointmentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barberOwnerProvider.notifier).loadAppointments(
        date: _filterDate,
        status: _filterStatus,
      );
    });
  }

  void _reload() {
    ref.read(barberOwnerProvider.notifier).loadAppointments(
      date: _filterDate,
      status: _filterStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(barberOwnerProvider);
    final appointments = owner.appointments;

    return AppScaffold(
      currentIndex: 1,
      title: 'Randevular',
      child: Column(
        children: [
          _FilterBar(
            selectedDate: _filterDate,
            selectedStatus: _filterStatus,
            onDateChanged: (date) {
              setState(() => _filterDate = date);
              _reload();
            },
            onStatusChanged: (status) {
              setState(() => _filterStatus = status);
              _reload();
            },
            onClear: () {
              setState(() {
                _filterDate = null;
                _filterStatus = null;
              });
              _reload();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: appointments.isEmpty
                  ? const Center(child: Text('Randevu bulunmuyor.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          onConfirm: appointment.status == AppointmentStatus.pending
                              ? () => _confirm(appointment.id)
                              : null,
                          onComplete: appointment.status == AppointmentStatus.confirmed
                              ? () => _complete(appointment.id)
                              : null,
                          onReject: appointment.status == AppointmentStatus.pending
                              ? () => _reject(appointment.id)
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(String id) async {
    final success = await ref.read(barberOwnerProvider.notifier).confirmAppointment(id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onaylama başarısız oldu.')),
      );
    }
  }

  Future<void> _complete(String id) async {
    final success = await ref.read(barberOwnerProvider.notifier).completeAppointment(id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tamamlama başarısız oldu.')),
      );
    }
  }

  Future<void> _reject(String id) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;
    final success = await ref.read(barberOwnerProvider.notifier).rejectAppointment(id, reason: reason);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reddetme başarısız oldu.')),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Randevu Reddet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reddetme sebebi (isteğe bağlı)',
            hintText: 'Sebep yazın...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reddet', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result?.isEmpty == true ? null : result;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedDate,
    required this.selectedStatus,
    required this.onDateChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final AppointmentStatus? selectedStatus;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<AppointmentStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                onDateChanged(date);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                selectedDate == null
                    ? 'Tarih'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<AppointmentStatus?>(
              value: selectedStatus,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Durum'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tümü')),
                DropdownMenuItem(value: AppointmentStatus.pending, child: Text('Bekliyor')),
                DropdownMenuItem(value: AppointmentStatus.confirmed, child: Text('Onaylı')),
                DropdownMenuItem(value: AppointmentStatus.completed, child: Text('Tamamlandı')),
                DropdownMenuItem(value: AppointmentStatus.cancelled, child: Text('İptal')),
                DropdownMenuItem(value: AppointmentStatus.rejected, child: Text('Reddedildi')),
              ],
              onChanged: (value) => onStatusChanged(value),
            ),
          ),
          if (selectedDate != null || selectedStatus != null)
            IconButton(
              tooltip: 'Filtreleri temizle',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    this.onConfirm,
    this.onComplete,
    this.onReject,
  });

  final Appointment appointment;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.customerName ?? 'Müşteri',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}  '
              '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')} - '
              '${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              appointment.services.join(', '),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              '₺${appointment.totalPrice}  •  ${appointment.staffName}',
              style: AppTextStyles.caption,
            ),
            if (appointment.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reddetme sebebi: ${appointment.rejectionReason}',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ],
            if (onConfirm != null || onComplete != null || onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onConfirm != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (onReject != null) ...[
                    if (onConfirm != null) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reddet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  if (onComplete != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AppointmentStatus.pending => (AppColors.warning, 'Bekliyor'),
      AppointmentStatus.confirmed => (AppColors.info, 'Onaylı'),
      AppointmentStatus.completed => (AppColors.success, 'Tamamlandı'),
      AppointmentStatus.cancelled => (AppColors.textMuted, 'İptal'),
      AppointmentStatus.rejected => (AppColors.error, 'Reddedildi'),
      _ => (AppColors.textMuted, 'Bilinmiyor'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
