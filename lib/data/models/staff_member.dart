class StaffMember {
  const StaffMember({
    required this.id,
    required this.businessId,
    required this.fullName,
    required this.role,
    required this.active,
    this.avatarUrl,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String? ?? 'Personel',
        active: json['active'] as bool? ?? true,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String id;
  final String businessId;
  final String fullName;
  final String role;
  final bool active;
  final String? avatarUrl;
}
