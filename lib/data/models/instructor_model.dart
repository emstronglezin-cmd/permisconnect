class InstructorModel {
  final String id;
  final String profileId;
  final String? licenseNumber;
  final String? specialization;
  final bool isAvailable;
  final int totalLessons;
  final double rating;
  final DateTime createdAt;

  // Données jointes depuis profiles
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const InstructorModel({
    required this.id,
    required this.profileId,
    this.licenseNumber,
    this.specialization,
    this.isAvailable = true,
    this.totalLessons = 0,
    this.rating = 0.0,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return InstructorModel(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      licenseNumber: json['license_number'] as String?,
      specialization: json['specialization'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      totalLessons: json['total_lessons'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      fullName: profileData?['full_name'] as String?,
      phone: profileData?['phone'] as String?,
      avatarUrl: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'license_number': licenseNumber,
      'specialization': specialization,
      'is_available': isAvailable,
      'total_lessons': totalLessons,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
