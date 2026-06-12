class StudentModel {
  final String id;
  final String profileId;
  final String? registrationNumber;
  final String? formula;
  final String status;
  final DateTime? enrollmentDate;
  final DateTime? examDate;
  final int hoursCompleted;
  final int hoursRequired;
  final int quizScore;
  final String? instructorId;
  final String? notes;
  final DateTime createdAt;

  // Données jointes depuis profiles
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? email;

  const StudentModel({
    required this.id,
    required this.profileId,
    this.registrationNumber,
    this.formula,
    this.status = 'active',
    this.enrollmentDate,
    this.examDate,
    this.hoursCompleted = 0,
    this.hoursRequired = 20,
    this.quizScore = 0,
    this.instructorId,
    this.notes,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.email,
  });

  double get progressPercent =>
      hoursRequired > 0 ? (hoursCompleted / hoursRequired).clamp(0.0, 1.0) : 0;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // Gestion des données jointes (profiles)
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return StudentModel(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      registrationNumber: json['registration_number'] as String?,
      formula: json['formula'] as String?,
      status: json['status'] as String? ?? 'active',
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.parse(json['enrollment_date'] as String)
          : null,
      examDate: json['exam_date'] != null
          ? DateTime.parse(json['exam_date'] as String)
          : null,
      hoursCompleted: json['hours_completed'] as int? ?? 0,
      hoursRequired: json['hours_required'] as int? ?? 20,
      quizScore: json['quiz_score'] as int? ?? 0,
      instructorId: json['instructor_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      // Données jointes
      fullName: profileData?['full_name'] as String?,
      phone: profileData?['phone'] as String?,
      avatarUrl: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'registration_number': registrationNumber,
      'formula': formula,
      'status': status,
      'enrollment_date': enrollmentDate?.toIso8601String(),
      'exam_date': examDate?.toIso8601String(),
      'hours_completed': hoursCompleted,
      'hours_required': hoursRequired,
      'quiz_score': quizScore,
      'instructor_id': instructorId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
