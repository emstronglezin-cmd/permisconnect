class QuizCategoryEntity {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int questionCount;
  final String color;
  final int orderIndex;
  final bool isActive;

  QuizCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.questionCount,
    required this.color,
    required this.orderIndex,
    required this.isActive,
  });
}

class QuizQuestionEntity {
  final String id;
  final String categoryId;
  final String questionText;
  final String? imageUrl;
  final String explanation;
  final String difficulty;
  final List<QuizAnswerEntity> answers;
  final bool isActive;

  QuizQuestionEntity({
    required this.id,
    required this.categoryId,
    required this.questionText,
    this.imageUrl,
    required this.explanation,
    required this.difficulty,
    required this.answers,
    required this.isActive,
  });

  QuizAnswerEntity get correctAnswer =>
      answers.firstWhere((a) => a.isCorrect);
}

class QuizAnswerEntity {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final int orderIndex;

  QuizAnswerEntity({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.isCorrect,
    required this.orderIndex,
  });
}

class QuizAttemptEntity {
  final String id;
  final String studentId;
  final String? categoryId;
  final String attemptType;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int timeSpentSeconds;
  final bool isPassed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<QuizAnswerResultEntity> answers;

  QuizAttemptEntity({
    required this.id,
    required this.studentId,
    this.categoryId,
    required this.attemptType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeSpentSeconds,
    required this.isPassed,
    required this.startedAt,
    this.completedAt,
    required this.answers,
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
}

class QuizAnswerResultEntity {
  final String questionId;
  final String selectedAnswerId;
  final bool isCorrect;
  final int timeSpentSeconds;

  QuizAnswerResultEntity({
    required this.questionId,
    required this.selectedAnswerId,
    required this.isCorrect,
    required this.timeSpentSeconds,
  });
}
