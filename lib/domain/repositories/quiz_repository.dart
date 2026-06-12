import '../../data/models/quiz_model.dart';

abstract class QuizRepository {
  /// Toutes les catégories de quiz
  Future<List<QuizCategoryModel>> getCategories();

  /// Questions d'une catégorie
  Future<List<QuizQuestionModel>> getQuestionsByCategory(
    String categoryId, {
    int limit = 20,
  });

  /// Sauvegarder un résultat de quiz
  Future<QuizAttemptModel> saveAttempt({
    required String studentId,
    required String categoryId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int durationSeconds,
  });

  /// Historique des tentatives de l'élève
  Future<List<QuizAttemptModel>> getMyAttempts();

  /// Compétences de conduite de l'élève
  Future<List<StudentSkillModel>> getMySkills();
}
