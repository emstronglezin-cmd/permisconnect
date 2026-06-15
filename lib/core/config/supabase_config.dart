/// Configuration Supabase — PermisConnect
/// La publishableKey (sb_publishable_...) est la clé publique du nouveau format Supabase.
/// La clé privée LeekPay est UNIQUEMENT dans les Edge Functions Supabase.

class SupabaseConfig {
  static const String url = 'https://hruisploxlmhigbsnzbn.supabase.co';

  /// Publishable Key Supabase (format nouveau — remplace l'anon key JWT)
  /// Utilisée avec publishableKey: dans Supabase.initialize()
  static const String publishableKey =
      'sb_publishable_fNfoJ2htxpDorg2MXpRkTg_hDHnLzgF';

  // Noms des tables Supabase
  static const String tableProfiles = 'profiles';
  static const String tableStudents = 'students';
  static const String tableInstructors = 'instructors';
  static const String tableVehicles = 'vehicles';
  static const String tableDrivingLessons = 'driving_lessons';
  static const String tablePayments = 'payments';
  static const String tableNotifications = 'notifications';
  static const String tableQuizCategories = 'quiz_categories';
  static const String tableQuizQuestions = 'quiz_questions';
  static const String tableQuizAnswers = 'quiz_answers';
  static const String tableQuizAttempts = 'quiz_attempts';
  static const String tableDrivingSkills = 'driving_skills';
  static const String tableStudentSkills = 'student_skills';

  // Noms des Edge Functions
  static const String fnCreatePayment = 'create-payment';
  static const String fnVerifyPayment = 'verify-payment';

  // Rôles utilisateurs
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleInstructor = 'instructor';
}
