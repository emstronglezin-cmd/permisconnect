class QuizCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String color;
  final int questionCount;
  final bool isActive;
  final int orderIndex;

  const QuizCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.color = '#1E65C5',
    this.questionCount = 0,
    this.isActive = true,
    this.orderIndex = 0,
  });

  // Pas de iconName dans le schéma réel - retourne null
  String? get iconName => null;

  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuizCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#1E65C5',
      questionCount: json['question_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color': color,
        'question_count': questionCount,
        'is_active': isActive,
        'order_index': orderIndex,
      };
}

class QuizQuestionModel {
  final String id;
  final String categoryId;
  final String question;        // question_text dans la DB
  final List<String> options;   // construites depuis quiz_answers
  final int correctOptionIndex; // index de la bonne réponse dans options
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
    this.difficulty = 'MEDIUM',
    this.points = 1,
  });

  /// Construit depuis quiz_questions + quiz_answers joints
  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    List<String> opts = [];
    int correctIdx = 0;

    final rawAnswers = json['quiz_answers'];
    if (rawAnswers is List && rawAnswers.isNotEmpty) {
      // Trier par order_index
      final sorted = List<Map<String, dynamic>>.from(
          rawAnswers.map((a) => a as Map<String, dynamic>))
        ..sort((a, b) => (a['order_index'] as int? ?? 0)
            .compareTo(b['order_index'] as int? ?? 0));
      opts = sorted.map((a) => a['answer_text'] as String? ?? '').toList();
      int idx = 0;
      for (final ans in sorted) {
        if (ans['is_correct'] == true) {
          correctIdx = idx;
          break;
        }
        idx++;
      }
    } else if (json['options'] is List) {
      // Fallback si options est fourni directement (compatibilité future)
      opts = (json['options'] as List).map((e) => e.toString()).toList();
      correctIdx = json['correct_option_index'] as int? ?? 0;
    }

    final diffRaw = json['difficulty'] as String? ?? 'MEDIUM';
    final points = diffRaw == 'HARD' ? 2 : 1;

    return QuizQuestionModel(
      id: json['id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      question: json['question_text'] as String?
          ?? json['question'] as String? ?? '',
      options: opts,
      correctOptionIndex: correctIdx,
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?,
      difficulty: diffRaw.toLowerCase(),
      points: points,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'question_text': question,
        'explanation': explanation,
        'image_url': imageUrl,
        'difficulty': difficulty.toUpperCase(),
      };
}

class QuizAttemptModel {
  final String id;
  final String studentId;
  final String categoryId;
  final int score;           // correct_answers dans la DB
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;
  final DateTime createdAt;  // started_at dans la DB
  final bool isPassed;

  const QuizAttemptModel({
    required this.id,
    required this.studentId,
    required this.categoryId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.createdAt,
    this.isPassed = false,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final correct = (json['correct_answers'] as int?) ?? (json['score'] as int?) ?? 0;
    final total = json['total_questions'] as int? ?? 0;
    final pct = total > 0 ? (correct / total) * 100 : 0.0;
    return QuizAttemptModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      score: correct,
      totalQuestions: total,
      correctAnswers: correct,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      createdAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      isPassed: json['is_passed'] as bool? ?? pct >= 70,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'category_id': categoryId,
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'score_percentage':
            totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0,
        'is_passed': isPassed,
        'started_at': createdAt.toIso8601String(),
      };
}

class StudentSkillModel {
  final String id;
  final String studentId;
  final String skillId;
  final int level;
  final String? notes;
  final DateTime evaluatedAt;

  // Données jointes depuis driving_skills
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
      notes: json['comment'] as String?,
      evaluatedAt: json['validated_at'] != null
          ? DateTime.parse(json['validated_at'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      skillName: skillData?['name'] as String?,
      skillCategory: skillData?['category'] as String?,
    );
  }
}
