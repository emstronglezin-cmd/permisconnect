class UserEntity {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isInstructor => role == 'instructor';
  bool get isAdmin => role == 'admin';
}

class StudentEntity {
  final String id;
  final String profileId;
  final String? formula;
  final DateTime? enrollmentDate;
  final int hoursCompleted;
  final int hoursRequired;
  final String status;

  StudentEntity({
    required this.id,
    required this.profileId,
    this.formula,
    this.enrollmentDate,
    required this.hoursCompleted,
    required this.hoursRequired,
    required this.status,
  });

  double get progressPercentage =>
      hoursRequired > 0 ? (hoursCompleted / hoursRequired) * 100 : 0;
}

class InstructorEntity {
  final String id;
  final String profileId;
  final String? licenseNumber;
  final String? specialization;
  final double rating;
  final bool isAvailable;

  InstructorEntity({
    required this.id,
    required this.profileId,
    this.licenseNumber,
    this.specialization,
    required this.rating,
    required this.isAvailable,
  });
}
