import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../presentation/providers/lesson_provider.dart';
import '../../../presentation/providers/quiz_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final studentAsync = ref.watch(myStudentProvider);
    final upcomingAsync = ref.watch(upcomingLessonsProvider);
    final attemptsAsync = ref.watch(myQuizAttemptsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      const Color(0xFF0D3D7A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: profileAsync.when(
                      data: (profile) => Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            backgroundImage: profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                            child: profile?.avatarUrl == null
                                ? Text(
                                    (profile?.fullName ?? 'E')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bonjour 👋',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  profile?.fullName ?? 'Élève',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Corps ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Carte progression
                studentAsync.when(
                  data: (student) => student != null
                      ? _ProgressCard(
                          hoursCompleted: student.hoursCompleted,
                          hoursRequired: student.hoursRequired,
                          quizScore: student.quizScore,
                          status: student.status,
                        )
                      : _ProgressCard(
                          hoursCompleted: 0,
                          hoursRequired: 20,
                          quizScore: 0,
                          status: 'active',
                        ),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => const _ProgressCard(
                    hoursCompleted: 0,
                    hoursRequired: 20,
                    quizScore: 0,
                    status: 'active',
                  ),
                ),
                const SizedBox(height: 20),

                // Statistiques quiz
                attemptsAsync.when(
                  data: (attempts) {
                    final total = attempts.length;
                    final passed =
                        attempts.where((a) => a.isPassed).length;
                    final bestScore = attempts.isEmpty
                        ? 0
                        : attempts
                            .map((a) => a.percentage)
                            .reduce((a, b) => a > b ? a : b)
                            .round();

                    return _StatsRow(
                      total: total,
                      passed: passed,
                      bestScore: bestScore,
                    );
                  },
                  loading: () => const _LoadingCard(),
                  error: (_, __) =>
                      const _StatsRow(total: 0, passed: 0, bestScore: 0),
                ),
                const SizedBox(height: 20),

                // Actions rapides
                _SectionTitle(title: 'Actions rapides'),
                const SizedBox(height: 12),
                _QuickActions(),
                const SizedBox(height: 20),

                // Prochains cours
                _SectionTitle(title: 'Prochains cours'),
                const SizedBox(height: 12),
                upcomingAsync.when(
                  data: (lessons) => lessons.isEmpty
                      ? _EmptyState(
                          icon: Icons.event_available,
                          message: 'Aucun cours planifié',
                        )
                      : Column(
                          children: lessons
                              .map((l) => _LessonCard(lesson: l))
                              .toList(),
                        ),
                  loading: () => const _LoadingCard(),
                  error: (e, _) => _ErrorState(message: e.toString()),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte Progression ────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int hoursCompleted;
  final int hoursRequired;
  final int quizScore;
  final String status;

  const _ProgressCard({
    required this.hoursCompleted,
    required this.hoursRequired,
    required this.quizScore,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        hoursRequired > 0 ? hoursCompleted / hoursRequired : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Ma progression',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'active' ? 'Actif' : status,
                  style: TextStyle(
                    color: status == 'active' ? AppColors.success : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heures de conduite',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hoursCompleted / $hoursRequired h',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score quiz',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quizScore pts',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% complété',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Ligne Statistiques ───────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int passed;
  final int bestScore;

  const _StatsRow({
    required this.total,
    required this.passed,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                icon: Icons.quiz,
                value: '$total',
                label: 'Quiz tentés',
                color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: Icons.check_circle,
                value: '$passed',
                label: 'Réussis',
                color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: Icons.star,
                value: '$bestScore%',
                label: 'Meilleur',
                color: AppColors.accent)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Actions Rapides ──────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _ActionButton(
          icon: Icons.quiz,
          label: 'Faire un Quiz',
          color: AppColors.primary,
          onTap: () => context.go('/student/quiz'),
        ),
        _ActionButton(
          icon: Icons.calendar_month,
          label: 'Mon Agenda',
          color: AppColors.success,
          onTap: () => context.go('/student/agenda'),
        ),
        _ActionButton(
          icon: Icons.menu_book,
          label: 'Mon Livret',
          color: AppColors.accent,
          onTap: () => context.go('/student/livret'),
        ),
        _ActionButton(
          icon: Icons.person,
          label: 'Mon Profil',
          color: Colors.purple,
          onTap: () => context.go('/student/profile'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte Leçon ──────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final dynamic lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_car, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.instructorName ?? 'Moniteur',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${lesson.scheduledAt.day}/${lesson.scheduledAt.month}/${lesson.scheduledAt.year} '
                  '${lesson.scheduledAt.hour.toString().padLeft(2, '0')}:${lesson.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                if (lesson.location != null)
                  Text(
                    lesson.location!,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${lesson.durationMinutes} min',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Erreur de chargement',
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }
}
