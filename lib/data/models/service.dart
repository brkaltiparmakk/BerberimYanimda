class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.active,
    this.description,
    this.categoryId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['duration_minutes'] as int,
        active: json['active'] as bool? ?? true,
        description: json['description'] as String?,
        categoryId: json['category_id'] as String?,
      );

  final String id;
  final String businessId;
  final String name;
  final double price;
  final int durationMinutes;
  final bool active;
  final String? description;
  final String? categoryId;
}
