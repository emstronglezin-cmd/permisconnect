class AppConstants {
  // App Info
  static const String appName = 'PermisConnect';
  static const String appTagline = 'Votre Auto-École Digitale';
  static const String appVersion = '1.0.0';

  // Supabase (à remplacer par vos vraies clés)
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeStudentHome = '/student/home';
  static const String routeStudentQuiz = '/student/quiz';
  static const String routeStudentAgenda = '/student/agenda';
  static const String routeStudentLivret = '/student/livret';
  static const String routeStudentProfile = '/student/profile';
  static const String routeQuizDetail = '/student/quiz/:id';
  static const String routeQuizSession = '/student/quiz/session/:id';
  static const String routeQuizResult = '/student/quiz/result/:id';
  static const String routeAdminHome = '/admin/home';
  static const String routeAdminStudents = '/admin/students';
  static const String routeAdminInstructors = '/admin/instructors';
  static const String routeAdminVehicles = '/admin/vehicles';
  static const String routeAdminPlanning = '/admin/planning';
  static const String routeAdminPayments = '/admin/payments';
  static const String routeAdminSettings = '/admin/settings';

  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyOfflineMode = 'offline_mode';

  // Hive Boxes
  static const String boxQuizQuestions = 'quiz_questions';
  static const String boxQuizCategories = 'quiz_categories';
  static const String boxUserData = 'user_data';
  static const String boxOfflineQueue = 'offline_queue';

  // Quiz
  static const int quizTimeSeconds = 30;
  static const int quizPassScore = 35;
  static const int quizTotalQuestions = 40;

  // Pagination
  static const int defaultPageSize = 20;

  // Roles
  static const String roleStudent = 'student';
  static const String roleInstructor = 'instructor';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Payment Methods
  static const String paymentCash = 'CASH';
  static const String paymentOrangeMoney = 'ORANGE_MONEY';
  static const String paymentMoovMoney = 'MOOV_MONEY';
  static const String paymentCard = 'CARD';

  // Lesson Status
  static const String lessonPending = 'PENDING';
  static const String lessonConfirmed = 'CONFIRMED';
  static const String lessonCompleted = 'COMPLETED';
  static const String lessonCancelled = 'CANCELLED';

  // Skill Levels
  static const String skillNotStarted = 'NOT_STARTED';
  static const String skillInProgress = 'IN_PROGRESS';
  static const String skillValidated = 'VALIDATED';

  // Table Names (Supabase)
  static const String tableUsers = 'users';
  static const String tableStudents = 'students';
  static const String tableInstructors = 'instructors';
  static const String tableVehicles = 'vehicles';
  static const String tableDrivingLessons = 'driving_lessons';
  static const String tableLessonAssignments = 'lesson_assignments';
  static const String tablePayments = 'payments';
  static const String tableQuizCategories = 'quiz_categories';
  static const String tableQuizQuestions = 'quiz_questions';
  static const String tableQuizAnswers = 'quiz_answers';
  static const String tableQuizAttempts = 'quiz_attempts';
  static const String tableDrivingSkills = 'driving_skills';
  static const String tableStudentSkills = 'student_skills';
  static const String tableNotifications = 'notifications';

  // Animations Duration
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
