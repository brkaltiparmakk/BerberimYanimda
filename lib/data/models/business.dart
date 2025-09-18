class Business {
  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.published,
    this.description,
    this.coverImageUrl,
    this.averageRating,
    this.reviewCount,
    this.distanceKm,
    this.openHours,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        published: json['published'] as bool? ?? false,
        description: json['description'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        openHours: json['open_hours'] as Map<String, dynamic>?,
      );

  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool published;
  final String? description;
  final String? coverImageUrl;
  final double? averageRating;
  final int? reviewCount;
  final double? distanceKm;
  final Map<String, dynamic>? openHours;
}
