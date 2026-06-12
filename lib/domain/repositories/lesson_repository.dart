import '../../data/models/lesson_model.dart';

abstract class LessonRepository {
  /// Leçons de l'élève connecté
  Future<List<LessonModel>> getMyLessons();

  /// Toutes les leçons pour un jour donné (admin/moniteur)
  Future<List<LessonModel>> getLessonsByDate(DateTime date);

  /// Toutes les leçons (admin)
  Future<List<LessonModel>> getAllLessons({DateTime? from, DateTime? to});

  /// Créer une leçon (admin)
  Future<LessonModel> createLesson(Map<String, dynamic> data);

  /// Annuler une leçon
  Future<void> cancelLesson(String lessonId);
}
