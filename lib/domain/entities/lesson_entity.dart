class DrivingLessonEntity {
  final String id;
  final String studentId;
  final String instructorId;
  final String vehicleId;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final String lessonType;
  final String status;
  final String? location;
  final String? notes;
  final StudentProgressEntity? progress;
  final String? instructorName;
  final String? vehiclePlate;
  final DateTime createdAt;

  DrivingLessonEntity({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.vehicleId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.lessonType,
    required this.status,
    this.location,
    this.notes,
    this.progress,
    this.instructorName,
    this.vehiclePlate,
    required this.createdAt,
  });

  bool get isUpcoming =>
      scheduledDate.isAfter(DateTime.now()) && status == 'CONFIRMED';
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }
}

class VehicleEntity {
  final String id;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String vehicleType;
  final String status;
  final String? color;
  final int? mileage;
  final String? imageUrl;

  VehicleEntity({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.status,
    this.color,
    this.mileage,
    this.imageUrl,
  });
}

class StudentProgressEntity {
  final String id;
  final String lessonId;
  final String studentId;
  final String instructorId;
  final Map<String, SkillEvaluationEntity> skills;
  final String? generalComment;
  final int overallRating;
  final DateTime evaluatedAt;

  StudentProgressEntity({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.instructorId,
    required this.skills,
    this.generalComment,
    required this.overallRating,
    required this.evaluatedAt,
  });
}

class SkillEvaluationEntity {
  final String skillId;
  final String skillName;
  final int level;
  final String? comment;

  SkillEvaluationEntity({
    required this.skillId,
    required this.skillName,
    required this.level,
    this.comment,
  });
}

class DrivingSkillEntity {
  final String id;
  final String name;
  final String category;
  final String? description;
  final int orderIndex;
  final bool isRequired;

  DrivingSkillEntity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.orderIndex,
    required this.isRequired,
  });
}
