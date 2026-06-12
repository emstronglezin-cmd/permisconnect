class QuizCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String color;
  final int questionCount;
  final bool isActive;

  const QuizCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.color = '#1E65C5',
    this.questionCount = 0,
    this.isActive = true,
  });

  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuizCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      color: json['color'] as String? ?? '#1E65C5',
      questionCount: json['question_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon_name': iconName,
        'color': color,
        'question_count': questionCount,
        'is_active': isActive,
      };
}

class QuizQuestionModel {
  final String id;
  final String categoryId;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final String? imageUrl;
  final String difficulty;
  final int points;

  const QuizQuestionModel({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    this.imageUrl,
    this.difficulty = 'medium',
    this.points = 1,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    // Les options peuvent être stockées en JSON ou comme liste
    List<String> parseOptions(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return QuizQuestionModel(
      id: json['id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: parseOptions(json['options']),
      correctOptionIndex: json['correct_option_index'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      points: json['points'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'question': question,
        'options': options,
        'correct_option_index': correctOptionIndex,
        'explanation': explanation,
        'image_url': imageUrl,
        'difficulty': difficulty,
        'points': points,
      };
}

class QuizAttemptModel {
  final String id;
  final String studentId;
  final String categoryId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;
  final DateTime createdAt;

  const QuizAttemptModel({
    required this.id,
    required this.studentId,
    required this.categoryId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.createdAt,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  bool get isPassed => percentage >= 70;

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'category_id': categoryId,
        'score': score,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'duration_seconds': durationSeconds,
        'created_at': createdAt.toIso8601String(),
      };
}

class StudentSkillModel {
  final String id;
  final String studentId;
  final String skillId;
  final int level;
  final String? notes;
  final DateTime evaluatedAt;

  // Données jointes
  final String? skillName;
  final String? skillCategory;

  const StudentSkillModel({
    required this.id,
    required this.studentId,
    required this.skillId,
    required this.level,
    this.notes,
    required this.evaluatedAt,
    this.skillName,
    this.skillCategory,
  });

  factory StudentSkillModel.fromJson(Map<String, dynamic> json) {
    final skillData = json['driving_skills'] as Map<String, dynamic>?;
    return StudentSkillModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      skillId: json['skill_id'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      notes: json['notes'] as String?,
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'] as String)
          : DateTime.now(),
      skillName: skillData?['name'] as String?,
      skillCategory: skillData?['category'] as String?,
    );
  }
}
