class UserEntity {
  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserEntity({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isStudent => role == 'student';
  bool get isInstructor => role == 'instructor';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
}

class StudentEntity {
  final String id;
  final UserEntity user;
  final String? formula;
  final DateTime? enrollmentDate;
  final int hoursCompleted;
  final int hoursRequired;
  final String status;
  final double totalPaid;
  final double totalAmount;
  final String? schoolId;

  StudentEntity({
    required this.id,
    required this.user,
    this.formula,
    this.enrollmentDate,
    required this.hoursCompleted,
    required this.hoursRequired,
    required this.status,
    required this.totalPaid,
    required this.totalAmount,
    this.schoolId,
  });

  double get remainingAmount => totalAmount - totalPaid;
  double get progressPercentage =>
      hoursRequired > 0 ? (hoursCompleted / hoursRequired) * 100 : 0;
  bool get isFullyPaid => totalPaid >= totalAmount;
}

class InstructorEntity {
  final String id;
  final UserEntity user;
  final String licenseNumber;
  final List<String> vehicleTypes;
  final int totalLessonsGiven;
  final double rating;
  final String status;

  InstructorEntity({
    required this.id,
    required this.user,
    required this.licenseNumber,
    required this.vehicleTypes,
    required this.totalLessonsGiven,
    required this.rating,
    required this.status,
  });
}
