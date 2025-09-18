import 'package:intl/intl.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.status,
    required this.totalAmount,
    required this.scheduledAt,
    this.staffId,
    this.services,
    this.paymentStatus,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        customerId: json['customer_id'] as String,
        staffId: json['staff_id'] as String?,
        status: json['status'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        services: json['services'] as List<dynamic>?,
        paymentStatus: json['payment_status'] as String?,
      );

  final String id;
  final String businessId;
  final String customerId;
  final String? staffId;
  final String status;
  final double totalAmount;
  final DateTime scheduledAt;
  final List<dynamic>? services;
  final String? paymentStatus;

  String get formattedDate => DateFormat.yMMMMEEEEd('tr_TR').add_Hm().format(scheduledAt.toLocal());
}
