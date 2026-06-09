import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/student/student_home_screen.dart';
import '../../presentation/screens/student/quiz_categories_screen.dart';
import '../../presentation/screens/student/quiz_session_screen.dart';
import '../../presentation/screens/student/quiz_result_screen.dart';
import '../../presentation/screens/student/agenda_screen.dart';
import '../../presentation/screens/student/livret_screen.dart';
import '../../presentation/screens/student/profile_screen.dart';
import '../../presentation/screens/admin/admin_home_screen.dart';
import '../../presentation/screens/admin/students_screen.dart';
import '../../presentation/screens/admin/instructors_screen.dart';
import '../../presentation/screens/admin/vehicles_screen.dart';
import '../../presentation/screens/admin/planning_screen.dart';
import '../../presentation/screens/admin/payments_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return StudentShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/student/home',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: '/student/quiz',
            builder: (context, state) => const QuizCategoriesScreen(),
          ),
          GoRoute(
            path: '/student/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: '/student/livret',
            builder: (context, state) => const LivretScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/student/quiz/session/:categoryId',
        builder: (context, state) => QuizSessionScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/student/quiz/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizResultScreen(
            score: extra?['score'] ?? 0,
            totalQuestions: extra?['totalQuestions'] ?? 0,
            correctAnswers: extra?['correctAnswers'] ?? 0,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/home',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/admin/instructors',
            builder: (context, state) => const InstructorsScreen(),
          ),
          GoRoute(
            path: '/admin/vehicles',
            builder: (context, state) => const VehiclesScreen(),
          ),
          GoRoute(
            path: '/admin/planning',
            builder: (context, state) => const PlanningScreen(),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
        ],
      ),
    ],
  );
});

class StudentShell extends StatefulWidget {
  final Widget child;

  const StudentShell({super.key, required this.child});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  final List<String> _routes = [
    '/student/home',
    '/student/quiz',
    '/student/agenda',
    '/student/livret',
    '/student/profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Accueil'),
                _buildNavItem(1, Icons.quiz_rounded, 'Quiz'),
                _buildNavItem(2, Icons.calendar_month_rounded, 'Agenda'),
                _buildNavItem(3, Icons.menu_book_rounded, 'Livret'),
                _buildNavItem(4, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        context.go(_routes[index]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF1E65C5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E65C5)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF1E65C5)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<String> _routes = [
    '/admin/home',
    '/admin/students',
    '/admin/instructors',
    '/admin/planning',
    '/admin/payments',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.school_rounded, 'Élèves'),
                _buildNavItem(2, Icons.badge_rounded, 'Moniteurs'),
                _buildNavItem(3, Icons.calendar_today_rounded, 'Planning'),
                _buildNavItem(4, Icons.payments_rounded, 'Paiements'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        context.go(_routes[index]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF1E65C5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E65C5)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF1E65C5)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
