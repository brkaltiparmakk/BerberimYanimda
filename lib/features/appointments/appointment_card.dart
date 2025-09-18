import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/appointment.dart';
import '../../widgets/atoms/primary_button.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, required this.onCancel, required this.onRate});

  final Appointment appointment;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  Color _statusColor(BuildContext context) {
    switch (appointment.status) {
      case 'approved':
        return Theme.of(context).colorScheme.primary;
      case 'pending':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMMEEEEd('tr_TR').add_Hm().format(appointment.scheduledAt.toLocal());
    final total = appointment.totalAmount.toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(formatted, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(appointment.status.toUpperCase()), backgroundColor: _statusColor(context).withOpacity(0.15)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tutar: $total ₺'),
            const SizedBox(height: 12),
            Row(
              children: [
                if (appointment.status == 'approved' || appointment.status == 'pending')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('İptal Et'),
                    ),
                  ),
                if (appointment.status == 'completed')
                  Expanded(
                    child: PrimaryButton(
                      onPressed: onRate,
                      label: 'Değerlendir',
                      icon: Icons.star_border,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
