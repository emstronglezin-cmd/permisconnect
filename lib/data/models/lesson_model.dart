class LessonModel {
  final String id;
  final String studentId;
  final String instructorId;
  final String? vehicleId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String type;
  final String status;
  final String? location;
  final String? notes;
  final double? rating;
  final DateTime createdAt;

  // Données jointes
  final String? studentName;
  final String? instructorName;
  final String? vehicleName;

  const LessonModel({
    required this.id,
    required this.studentId,
    required this.instructorId,
    this.vehicleId,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.type = 'driving',
    this.status = 'scheduled',
    this.location,
    this.notes,
    this.rating,
    required this.createdAt,
    this.studentName,
    this.instructorName,
    this.vehicleName,
  });

  bool get isUpcoming =>
      scheduledAt.isAfter(DateTime.now()) && status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  DateTime get endTime =>
      scheduledAt.add(Duration(minutes: durationMinutes));

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    // Jointures possibles
    final studentData = json['students'] as Map<String, dynamic>?;
    final studentProfile =
        studentData?['profiles'] as Map<String, dynamic>?;
    final instructorData = json['instructors'] as Map<String, dynamic>?;
    final instructorProfile =
        instructorData?['profiles'] as Map<String, dynamic>?;
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;

    return LessonModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      instructorId: json['instructor_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      type: json['type'] as String? ?? 'driving',
      status: json['status'] as String? ?? 'scheduled',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      studentName: studentProfile?['full_name'] as String?,
      instructorName: instructorProfile?['full_name'] as String?,
      vehicleName: vehicleData != null
          ? '${vehicleData['brand']} ${vehicleData['model']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'instructor_id': instructorId,
      'vehicle_id': vehicleId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'type': type,
      'status': status,
      'location': location,
      'notes': notes,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
