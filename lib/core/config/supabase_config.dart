/// Configuration Supabase — PermisConnect
/// Les clés sont intégrées ici (anon key = publique, sans risque)
/// La clé privée LeekPay est UNIQUEMENT dans les Edge Functions Supabase

class SupabaseConfig {
  static const String url = 'https://hruisploxlmhigbsnzbn.supabase.co';

  /// Clé publique Supabase (anon key) — sûre côté client
  static const String anonKey =
      'sb_publishable_fNfoJ2htxpDorg2MXpRkTg_hDHnLzgF';

  /// Clé publique LeekPay (pour initier le paiement côté client)
  static const String leekPayPublicKey =
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
  static const String tableAdminInvitations = 'admin_invitations';

  // Noms des Edge Functions
  static const String fnCreatePayment = 'create-payment';
  static const String fnVerifyPayment = 'verify-payment';

  // Rôles utilisateurs
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleInstructor = 'instructor';
}
