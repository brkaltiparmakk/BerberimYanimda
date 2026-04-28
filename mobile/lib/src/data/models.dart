enum AppointmentFilter { upcoming, past, cancelled }

enum AppointmentStatus {
  pending,
  confirmed,
  upcoming,
  completed,
  cancelled,
  rejected,
  noShow,
}

AppointmentStatus appointmentStatusFromJson(String? value) => switch (value) {
  'Pending' || 'pending' => AppointmentStatus.pending,
  'Confirmed' || 'confirmed' => AppointmentStatus.confirmed,
  'Upcoming' || 'upcoming' => AppointmentStatus.upcoming,
  'Completed' || 'completed' => AppointmentStatus.completed,
  'Cancelled' || 'cancelled' => AppointmentStatus.cancelled,
  'Rejected' || 'rejected' => AppointmentStatus.rejected,
  'NoShow' || 'noShow' => AppointmentStatus.noShow,
  _ => AppointmentStatus.pending,
};

DateTime parseDateTime(String date, String time) {
  final dateParts = date.split('-');
  final timeParts = time.split(':');
  if (dateParts.length != 3 || timeParts.length < 2) {
    throw FormatException('Invalid date/time format: $date $time');
  }
  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2]);
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if (year == null || month == null || day == null || hour == null || minute == null) {
    throw FormatException('Invalid date/time values: $date $time');
  }
  if (month < 1 || month > 12) throw FormatException('Invalid month: $month');
  if (day < 1 || day > 31) throw FormatException('Invalid day: $day');
  if (hour < 0 || hour > 23) throw FormatException('Invalid hour: $hour');
  if (minute < 0 || minute > 59) throw FormatException('Invalid minute: $minute');
  return DateTime(year, month, day, hour, minute);
}

num _num(Map<String, dynamic> json, String key) => (json[key] as num?) ?? 0;
String _str(Map<String, dynamic> json, String key) =>
    (json[key] as String?) ?? '';

class Barber {
  Barber({
    required this.id,
    required this.name,
    required this.district,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.startingPrice,
    required this.isAvailableToday,
    required this.imageUrl,
    required this.isFavorite,
    required this.description,
    required this.address,
    required this.services,
    required this.staff,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String district;
  final String city;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int startingPrice;
  final bool isAvailableToday;
  final String imageUrl;
  final bool isFavorite;
  final String description;
  final String address;
  final List<BarberService> services;
  final List<Staff> staff;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  factory Barber.fromListJson(Map<String, dynamic> json) => Barber(
    id: _str(json, 'id'),
    name: _str(json, 'name'),
    district: _str(json, 'district'),
    city: _str(json, 'city'),
    rating: _num(json, 'rating').toDouble(),
    reviewCount: _num(json, 'reviewCount').toInt(),
    distanceKm: _num(json, 'distanceKm').toDouble(),
    startingPrice: _num(json, 'startingPrice').toInt(),
    isAvailableToday: (json['isAvailableToday'] as bool?) ?? false,
    imageUrl: (json['coverImageUrl'] as String?) ?? '',
    isFavorite: (json['isFavorite'] as bool?) ?? false,
    description: '',
    address: '',
    services: const [],
    staff: const [],
    phoneNumber: json['phoneNumber'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  factory Barber.fromDetailJson(Map<String, dynamic> json) => Barber(
    id: _str(json, 'id'),
    name: _str(json, 'name'),
    district: _str(json, 'district'),
    city: _str(json, 'city'),
    rating: _num(json, 'rating').toDouble(),
    reviewCount: _num(json, 'reviewCount').toInt(),
    distanceKm: _num(json, 'distanceKm').toDouble(),
    startingPrice: _num(json, 'startingPrice').toInt(),
    isAvailableToday: true,
    imageUrl: (json['coverImageUrl'] as String?) ?? '',
    isFavorite: (json['isFavorite'] as bool?) ?? false,
    description: (json['description'] as String?) ?? '',
    address: (json['address'] as String?) ?? '',
    services: ((json['services'] as List<dynamic>?) ?? [])
        .map((item) => BarberService.fromJson(item as Map<String, dynamic>))
        .toList(),
    staff: ((json['staff'] as List<dynamic>?) ?? [])
        .map((item) => Staff.fromJson(item as Map<String, dynamic>))
        .toList(),
    phoneNumber: json['phoneNumber'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  Barber copyWith({bool? isFavorite}) => Barber(
    id: id,
    name: name,
    district: district,
    city: city,
    rating: rating,
    reviewCount: reviewCount,
    distanceKm: distanceKm,
    startingPrice: startingPrice,
    isAvailableToday: isAvailableToday,
    imageUrl: imageUrl,
    isFavorite: isFavorite ?? this.isFavorite,
    description: description,
    address: address,
    services: services,
    staff: staff,
    phoneNumber: phoneNumber,
    latitude: latitude,
    longitude: longitude,
  );
}

class BarberService {
  const BarberService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.description,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final int price;
  final String? description;

  factory BarberService.fromJson(Map<String, dynamic> json) => BarberService(
    id: _str(json, 'id'),
    name: _str(json, 'name'),
    durationMinutes: _num(json, 'durationMinutes').toInt(),
    price: _num(json, 'price').toInt(),
    description: json['description'] as String?,
  );
}

class Staff {
  const Staff({
    required this.id,
    required this.name,
    required this.expertise,
    required this.rating,
    required this.isAvailableToday,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String expertise;
  final double rating;
  final bool isAvailableToday;
  final String avatarUrl;

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: _str(json, 'id'),
    name: (json['fullName'] as String?) ?? _str(json, 'name'),
    expertise: (json['expertise'] as String?) ?? '',
    rating: _num(json, 'averageRating').toDouble(),
    isAvailableToday: (json['isAvailableToday'] as bool?) ?? false,
    avatarUrl: (json['avatarUrl'] as String?) ?? '',
  );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.barberName,
    required this.barberImageUrl,
    required this.dateTime,
    required this.endTime,
    required this.staffName,
    required this.services,
    required this.totalPrice,
    required this.status,
    this.customerName,
    this.rejectionReason,
    this.barberPhoneNumber,
    this.barberAddress,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String barberName;
  final String barberImageUrl;
  final DateTime dateTime;
  final DateTime endTime;
  final String staffName;
  final List<String> services;
  final int totalPrice;
  final AppointmentStatus status;
  final String? customerName;
  final String? rejectionReason;
  final String? barberPhoneNumber;
  final String? barberAddress;
  final double? latitude;
  final double? longitude;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final date = _str(json, 'appointmentDate');
    final start = _str(json, 'startTime');
    final end = _str(json, 'endTime');
    return Appointment(
      id: _str(json, 'id'),
      barberName: _str(json, 'barberName'),
      barberImageUrl: (json['barberImageUrl'] as String?) ?? '',
      dateTime: parseDateTime(date, start),
      endTime: parseDateTime(date, end),
      staffName: (json['staffName'] as String?) ?? 'Farketmez',
      services: ((json['services'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                (item as Map<String, dynamic>)['serviceName'] as String? ?? '',
          )
          .where((name) => name.isNotEmpty)
          .toList(),
      totalPrice: _num(json, 'totalPrice').toInt(),
      status: appointmentStatusFromJson(json['status'] as String?),
      customerName: json['customerName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      barberPhoneNumber: json['barberPhoneNumber'] as String?,
      barberAddress: json['barberAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String startTime;
  final String endTime;
  final bool isAvailable;

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startTime: _str(json, 'startTime'),
    endTime: _str(json, 'endTime'),
    isAvailable: (json['isAvailable'] as bool?) ?? false,
  );
}

class WorkingHour {
  const WorkingHour({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isClosed,
  });

  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isClosed;

  factory WorkingHour.fromJson(Map<String, dynamic> json) => WorkingHour(
    id: _str(json, 'id'),
    dayOfWeek: _num(json, 'dayOfWeek').toInt(),
    startTime: _str(json, 'startTime'),
    endTime: _str(json, 'endTime'),
    isClosed: (json['isClosed'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'isClosed': isClosed,
  };
}

class OwnerService {
  const OwnerService({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final int price;
  final bool isActive;

  factory OwnerService.fromJson(Map<String, dynamic> json) => OwnerService(
    id: _str(json, 'id'),
    name: _str(json, 'name'),
    description: json['description'] as String?,
    durationMinutes: _num(json, 'durationMinutes').toInt(),
    price: _num(json, 'price').toInt(),
    isActive: (json['isActive'] as bool?) ?? true,
  );
}

class OwnerStaff {
  const OwnerStaff({
    required this.id,
    required this.fullName,
    this.expertise,
    this.bio,
    this.avatarUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.isActive,
    required this.services,
  });

  final String id;
  final String fullName;
  final String? expertise;
  final String? bio;
  final String? avatarUrl;
  final double averageRating;
  final int reviewCount;
  final bool isActive;
  final List<BarberService> services;

  factory OwnerStaff.fromJson(Map<String, dynamic> json) => OwnerStaff(
    id: _str(json, 'id'),
    fullName: _str(json, 'fullName'),
    expertise: json['expertise'] as String?,
    bio: json['bio'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    averageRating: _num(json, 'averageRating').toDouble(),
    reviewCount: _num(json, 'reviewCount').toInt(),
    isActive: (json['isActive'] as bool?) ?? true,
    services: ((json['services'] as List<dynamic>?) ?? [])
        .map((item) => BarberService.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.profileImageUrl,
    required this.role,
    required this.isPhoneVerified,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final String role;
  final bool isPhoneVerified;

  String get firstName => fullName.trim().split(' ').first;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: _str(json, 'id'),
    fullName: _str(json, 'fullName'),
    phoneNumber: _str(json, 'phoneNumber'),
    email: json['email'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    role: _str(json, 'role'),
    isPhoneVerified: (json['isPhoneVerified'] as bool?) ?? false,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _str(json, 'id'),
        title: _str(json, 'title'),
        message: _str(json, 'message'),
        type: _str(json, 'type'),
        isRead: (json['isRead'] as bool?) ?? false,
        createdAt: DateTime.tryParse(_str(json, 'createdAt')) ?? DateTime.now(),
      );
}

class Review {
  const Review({
    required this.id,
    required this.appointmentId,
    required this.customerUserId,
    required this.customerName,
    required this.barberShopId,
    this.staffMemberId,
    this.staffName,
    required this.rating,
    this.comment,
    required this.isApproved,
    required this.createdAt,
  });

  final String id;
  final String appointmentId;
  final String customerUserId;
  final String customerName;
  final String barberShopId;
  final String? staffMemberId;
  final String? staffName;
  final int rating;
  final String? comment;
  final bool isApproved;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: _str(json, 'id'),
    appointmentId: _str(json, 'appointmentId'),
    customerUserId: _str(json, 'customerUserId'),
    customerName: _str(json, 'customerName'),
    barberShopId: _str(json, 'barberShopId'),
    staffMemberId: json['staffMemberId'] as String?,
    staffName: json['staffName'] as String?,
    rating: _num(json, 'rating').toInt(),
    comment: json['comment'] as String?,
    isApproved: (json['isApproved'] as bool?) ?? false,
    createdAt: DateTime.tryParse(_str(json, 'createdAt')) ?? DateTime.now(),
  );
}

class ReviewSummary {
  const ReviewSummary({
    required this.averageRating,
    required this.reviewCount,
  });

  final double averageRating;
  final int reviewCount;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
    averageRating: _num(json, 'averageRating').toDouble(),
    reviewCount: _num(json, 'reviewCount').toInt(),
  );
}

class CouponValidationResult {
  const CouponValidationResult({
    required this.isValid,
    required this.message,
    required this.discountAmount,
    required this.finalAmount,
  });

  final bool isValid;
  final String? message;
  final int discountAmount;
  final int finalAmount;

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) =>
      CouponValidationResult(
        isValid: (json['isValid'] as bool?) ?? false,
        message: json['message'] as String?,
        discountAmount: _num(json, 'discountAmount').toInt(),
        finalAmount: _num(json, 'finalAmount').toInt(),
      );
}
