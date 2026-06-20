class LessonModel {
  final String id;
  final String studentId;
  final String? instructorId;
  final String? vehicleId;
  final DateTime scheduledAt;   // Calculé depuis scheduled_date + start_time
  final DateTime? endAt;         // Calculé depuis scheduled_date + end_time
  final int durationMinutes;
  final String type;             // lesson_type dans la DB
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
    this.instructorId,
    this.vehicleId,
    required this.scheduledAt,
    this.endAt,
    this.durationMinutes = 60,
    this.type = 'DRIVING',
    this.status = 'PENDING',
    this.location,
    this.notes,
    this.rating,
    required this.createdAt,
    this.studentName,
    this.instructorName,
    this.vehicleName,
  });

  bool get isUpcoming =>
      scheduledAt.isAfter(DateTime.now()) &&
      (status == 'PENDING' || status == 'CONFIRMED' ||
       status == 'scheduled' || status == 'upcoming');

  bool get isCompleted => status == 'COMPLETED' || status == 'completed';
  bool get isCancelled => status == 'CANCELLED' || status == 'cancelled';

  DateTime get endTime =>
      endAt ?? scheduledAt.add(Duration(minutes: durationMinutes));

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    // Données jointes
    final instructorData = json['instructors'] as Map<String, dynamic>?;
    final instructorProfile =
        instructorData?['profiles'] as Map<String, dynamic>?;
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;

    // Construire scheduledAt depuis scheduled_date + start_time (schéma réel)
    // OU depuis scheduled_at (si la DB a été migrée)
    DateTime scheduledAt;
    DateTime? endAt;

    if (json['scheduled_at'] != null) {
      scheduledAt = DateTime.parse(json['scheduled_at'] as String);
    } else if (json['scheduled_date'] != null) {
      final dateStr = json['scheduled_date'] as String; // "2024-01-15"
      final startTimeStr = json['start_time'] as String? ?? '08:00:00';
      final endTimeStr = json['end_time'] as String?;
      try {
        final timeParts = startTimeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts.length > 1 ? timeParts[1] : '0');
        final date = DateTime.parse(dateStr);
        scheduledAt = DateTime(date.year, date.month, date.day, hour, minute);

        if (endTimeStr != null) {
          final endParts = endTimeStr.split(':');
          final endHour = int.parse(endParts[0]);
          final endMin = int.parse(endParts.length > 1 ? endParts[1] : '0');
          endAt = DateTime(date.year, date.month, date.day, endHour, endMin);
        }
      } catch (_) {
        scheduledAt = DateTime.now();
      }
    } else {
      scheduledAt = DateTime.now();
    }

    // Calculer la durée si possible
    int duration = 60;
    if (endAt != null) {
      duration = endAt.difference(scheduledAt).inMinutes;
      if (duration <= 0) duration = 60;
    }

    return LessonModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      instructorId: json['instructor_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      scheduledAt: scheduledAt,
      endAt: endAt,
      durationMinutes: duration,
      type: json['lesson_type'] as String? ?? json['type'] as String? ?? 'DRIVING',
      status: json['status'] as String? ?? 'PENDING',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      // Données jointes
      instructorName: instructorProfile?['full_name'] as String?,
      vehicleName: vehicleData != null
          ? '${vehicleData['brand'] ?? ''} ${vehicleData['model'] ?? ''}'.trim()
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
