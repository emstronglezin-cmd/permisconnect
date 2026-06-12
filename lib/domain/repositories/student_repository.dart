import '../../data/models/student_model.dart';

abstract class StudentRepository {
  /// Récupérer l'élève lié au profil connecté
  Future<StudentModel?> getMyStudent();

  /// Liste de tous les élèves (admin only)
  Future<List<StudentModel>> getAllStudents({String? search, String? status});

  /// Détail d'un élève
  Future<StudentModel?> getStudentById(String id);

  /// Mettre à jour les heures d'un élève
  Future<void> updateStudentHours(String studentId, int hours);
}
