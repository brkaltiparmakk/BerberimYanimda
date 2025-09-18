class Promotion {
  const Promotion({
    required this.id,
    required this.businessId,
    required this.title,
    required this.discountRate,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.description,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        title: json['title'] as String,
        discountRate: (json['discount_rate'] as num).toDouble(),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        active: json['active'] as bool? ?? true,
        description: json['description'] as String?,
      );

  final String id;
  final String businessId;
  final String title;
  final double discountRate;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final String? description;
}
