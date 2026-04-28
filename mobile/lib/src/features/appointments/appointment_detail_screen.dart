import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/danger_button.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/secondary_button.dart';
import 'package:berber_yanimda/src/core/widgets/feedback/status_badge.dart';
import 'package:berber_yanimda/src/core/widgets/layout/app_network_image.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('dd MMM yyyy').format(appointment.dateTime);
    final (statusText, statusColor) = _status(appointment.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Detay'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StatusBadge(text: statusText, color: statusColor),
            const SizedBox(height: 16),
            AppNetworkImage(
              url: appointment.barberImageUrl,
              height: 180,
              width: double.infinity,
              borderRadius: 16,
            ),
            const SizedBox(height: 16),
            Text(appointment.barberName, style: AppTextStyles.largeTitle),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Adres',
              value: appointment.barberAddress?.isNotEmpty == true
                  ? appointment.barberAddress!
                  : 'Adres bilgisi bulunamadı',
            ),
            _DetailRow(label: 'Tarih', value: date),
            _DetailRow(label: 'Saat', value: DateFormat('HH:mm').format(appointment.dateTime)),
            _DetailRow(label: 'Personel', value: appointment.staffName),
            _DetailRow(label: 'Hizmetler', value: appointment.services.join(', ')),
            _DetailRow(label: 'Tutar', value: '₺${appointment.totalPrice}', highlighted: true),
            const SizedBox(height: 24),
            SecondaryButton(
              text: 'Berberi Ara',
              icon: Icons.phone_outlined,
              onPressed: () => _launchPhoneCall(appointment.barberPhoneNumber),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              text: 'Yol Tarifi Al',
              icon: Icons.navigation_outlined,
              onPressed: () => _launchMapDirections(
                appointment.barberAddress,
                lat: appointment.latitude,
                lng: appointment.longitude,
              ),
            ),
            if (appointment.status != AppointmentStatus.cancelled &&
                appointment.status != AppointmentStatus.completed) ...[
              const SizedBox(height: 10),
              DangerButton(
                text: 'Randevuyu İptal Et',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Randevuyu İptal Et'),
                      content: const Text(
                        'Bu randevuyu iptal etmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Vazgeç'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('İptal Et'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final success = await ref.read(appointmentProvider.notifier).cancelAppointment(appointment.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Randevunuz iptal edildi.')),
                      );
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Randevu iptal edilemedi.')),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _status(AppointmentStatus status) => switch (status) {
    AppointmentStatus.confirmed => ('Yaklaşan', AppColors.primaryGold),
    AppointmentStatus.upcoming => ('Yaklaşan', AppColors.primaryGold),
    AppointmentStatus.completed => ('Tamamlandı', AppColors.textMuted),
    AppointmentStatus.cancelled => ('İptal', AppColors.error),
    AppointmentStatus.rejected => ('Reddedildi', AppColors.error),
    AppointmentStatus.noShow => ('Gelmedi', AppColors.error),
    AppointmentStatus.pending => ('Bekliyor', AppColors.warning),
  };
}

Future<void> _launchPhoneCall(String? phoneNumber) async {
  if (phoneNumber == null || phoneNumber.isEmpty) return;
  final cleaned = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _launchMapDirections(String? address, {double? lat, double? lng}) async {
  Uri uri;
  if (lat != null && lng != null) {
    uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  } else if (address != null && address.isNotEmpty) {
    final encoded = Uri.encodeComponent(address.trim());
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  } else {
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.highlighted = false});

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
          Expanded(
            child: Text(label, style: AppTextStyles.body),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(
                color: highlighted ? AppColors.primaryGold : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
