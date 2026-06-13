import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../presentation/providers/auth_provider.dart';
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
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final currentPath = state.matchedLocation;

      final isOnAuthPage = currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/';

      final isOnAdminRoute = currentPath.startsWith('/admin');
      final isOnStudentRoute = currentPath.startsWith('/student');

      // ── 1. Non connecté → login (sauf splash/auth) ──────────────────────
      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      // ── 2. Connecté sur une page d'auth → rediriger selon rôle ──────────
      if (isLoggedIn && isOnAuthPage && currentPath != '/') {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        if (profile == null) return null; // Attendre le chargement du profil

        if (profile.role == SupabaseConfig.roleAdmin) {
          return '/admin/home';
        } else {
          return '/student/home';
        }
      }

      // ── 3. GUARD ADMIN : Étudiant tentant d'accéder à /admin/* ──────────
      // SÉCURITÉ CRITIQUE : un étudiant ne peut JAMAIS accéder au dashboard admin
      if (isLoggedIn && isOnAdminRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;

        // Si le profil n'est pas encore chargé, attendre
        if (profile == null) return null;

        // Si l'utilisateur n'est pas admin → bloquer et rediriger
        if (profile.role != SupabaseConfig.roleAdmin) {
          debugPrint(
            '[Router] ACCÈS BLOQUÉ: ${profile.fullName} (${profile.role}) '
            'tentait d\'accéder à $currentPath → redirection /student/home',
          );
          return '/student/home';
        }
      }

      // ── 4. GUARD STUDENT : Admin tentant d'accéder à /student/* ─────────
      // Un admin ne doit pas utiliser l'espace élève (évite la confusion)
      if (isLoggedIn && isOnStudentRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;

        if (profile != null && profile.role == SupabaseConfig.roleAdmin) {
          return '/admin/home';
        }
      }

      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Espace Élève (avec bottom nav) ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/home',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: '/student/quiz',
            builder: (context, state) => const QuizCategoriesScreen(),
            routes: [
              GoRoute(
                path: 'session/:categoryId',
                builder: (context, state) => QuizSessionScreen(
                  categoryId: state.pathParameters['categoryId']!,
                  categoryName:
                      state.uri.queryParameters['name'] ?? 'Quiz',
                ),
                routes: [
                  GoRoute(
                    path: 'result',
                    builder: (context, state) => const QuizResultScreen(),
                  ),
                ],
              ),
            ],
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

      // ── Espace Admin (avec bottom nav) ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
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

// ─── Notifier pour rafraîchir le router quand l'auth change ──────────────────

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentProfileProvider, (_, __) => notifyListeners());
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STUDENT SHELL — Bottom Navigation Bar pour les élèves
// ═════════════════════════════════════════════════════════════════════════════

class StudentShell extends ConsumerWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;

    if (location.startsWith('/student/home')) {
      currentIndex = 0;
    } else if (location.startsWith('/student/quiz')) {
      currentIndex = 1;
    } else if (location.startsWith('/student/agenda')) {
      currentIndex = 2;
    } else if (location.startsWith('/student/livret')) {
      currentIndex = 3;
    } else if (location.startsWith('/student/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/student/home');
              break;
            case 1:
              context.go('/student/quiz');
              break;
            case 2:
              context.go('/student/agenda');
              break;
            case 3:
              context.go('/student/livret');
              break;
            case 4:
              context.go('/student/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Code',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Livret',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN SHELL — Bottom Navigation Bar pour les admins
// ═════════════════════════════════════════════════════════════════════════════

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;

    if (location.startsWith('/admin/home')) {
      currentIndex = 0;
    } else if (location.startsWith('/admin/students')) {
      currentIndex = 1;
    } else if (location.startsWith('/admin/planning')) {
      currentIndex = 2;
    } else if (location.startsWith('/admin/payments')) {
      currentIndex = 3;
    } else if (location.startsWith('/admin/instructors') ||
        location.startsWith('/admin/vehicles')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/admin/home');
              break;
            case 1:
              context.go('/admin/students');
              break;
            case 2:
              context.go('/admin/planning');
              break;
            case 3:
              context.go('/admin/payments');
              break;
            case 4:
              context.go('/admin/instructors');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Élèves',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Paiements',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts),
            label: 'Gestion',
          ),
        ],
      ),
    );
  }
}
